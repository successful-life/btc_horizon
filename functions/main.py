import json
import math
import os
import requests
from datetime import date, datetime, timedelta, timezone
from uuid import uuid4

from firebase_admin import firestore, initialize_app
from firebase_functions import https_fn, scheduler_fn, logger
from firebase_functions.options import set_global_options


initialize_app()

set_global_options(
    region="asia-northeast3",
    min_instances=0,
    max_instances=1,
    concurrency=1,
)


def json_response(data: dict, status: int = 200) -> https_fn.Response:
    return https_fn.Response(
        json.dumps(data, ensure_ascii=False),
        status=status,
        mimetype="application/json",
    )


def validate_points(points: list[dict]) -> None:
    """저장하기 전에 날짜·가격·점수를 검사합니다."""
    if not points:
        raise ValueError("데이터가 비어 있습니다.")

    seen_dates = set()

    for point in points:
        day = point["t"]

        # YYYY-MM-DD 형식과 실제로 존재하는 날짜인지 검사합니다.
        if not isinstance(day, str) or date.fromisoformat(day).isoformat() != day:
            raise ValueError("날짜 형식이 올바르지 않습니다.")

        if day in seen_dates:
            raise ValueError(f"날짜가 중복되었습니다: {day}")

        seen_dates.add(day)

        for field in ("usd", "mvrvZ"):
            value = point[field]

            if (
                isinstance(value, bool)
                or not isinstance(value, (int, float))
                or not math.isfinite(value)
            ):
                raise ValueError(f"{day}: {field} 값이 올바르지 않습니다.")

        if point["usd"] <= 0:
            raise ValueError(f"{day}: 가격은 0보다 커야 합니다.")

        # mvrvZ는 음수도 정상 값이므로 음수라는 이유로 거부하지 않습니다.

def fetch_mvrv_history() -> dict:
    """KOTE에서 실제 데이터를 받아 저장 가능한 형태인지 검사합니다."""
    api_key = os.environ.get("KOTE_API_KEY", "").strip()

    if not api_key:
        raise ValueError("KOTE_API_KEY가 설정되지 않았습니다.")

    response = requests.get(
        "https://kotecharts.com/api/v1/public/charts/mvrv-z-score",
        params={
            "from": "2010-01-01",
            "granularity": "day",
            "includePartial": "false",
        },
        headers={
            "X-API-Key": api_key,
            "Accept": "application/json",
        },
        timeout=(10, 30),
        allow_redirects=False,
    )

    if response.status_code != 200:
        raise ValueError(
            f"KOTE 요청 실패: HTTP {response.status_code}"
        )

    payload = response.json()

    if not isinstance(payload, dict) or payload.get("success") is not True:
        raise ValueError("KOTE API 응답이 올바르지 않습니다.")

    data = payload.get("data")

    if not isinstance(data, dict):
        raise ValueError("응답에 data 영역이 없습니다.")

    # 날짜 메타데이터를 검사합니다.
    for field in ("asOf", "completeThrough"):
        value = data.get(field)

        if (
            not isinstance(value, str)
            or date.fromisoformat(value).isoformat() != value
        ):
            raise ValueError(f"{field} 날짜가 올바르지 않습니다.")

    if data["completeThrough"] > data["asOf"]:
        raise ValueError("확정 데이터 날짜가 API 기준일보다 뒤에 있습니다.")

    source = data.get("source")

    if not isinstance(source, str) or not source.strip():
        raise ValueError("데이터 출처가 없습니다.")

    raw_series = data.get("series")

    if not isinstance(raw_series, list) or not raw_series:
        raise ValueError("시계열 데이터가 없거나 형식이 올바르지 않습니다.")

    points = []

    for item in raw_series:
        if not isinstance(item, dict):
            raise ValueError("시계열 항목이 올바르지 않습니다.")

        # 사용할 필드만 저장합니다.
        points.append({
            "t": item["t"],
            "usd": item["usd"],
            "mvrvZ": item["mvrvZ"],
        })

    validate_points(points)
    points.sort(key=lambda point: point["t"])

    if points[-1]["t"] > data["asOf"]:
        raise ValueError("API 기준일 이후의 데이터가 포함되어 있습니다.")

    # 현재 Flutter와 동일하게 확정된 날짜까지의 마지막 값을 찾습니다.
    confirmed = [
        point
        for point in points
        if point["t"] <= data["completeThrough"]
    ]

    if not confirmed:
        raise ValueError("확정된 데이터가 없습니다.")

    return {
        "source": source,
        "asOf": data["asOf"],
        "completeThrough": data["completeThrough"],
        "points": points,
        "latestConfirmed": confirmed[-1],
    }


# 수집 함수 아래에 실행 순서와 저장 방법을 모았습니다.
PROJECT_ID = "btc-horizon-dev"
JOB_PATH = "_server_jobs/mvrv_sync"
LEASE_SECONDS = 180


def require_local_firestore() -> str:
    host = os.environ.get("FIRESTORE_EMULATOR_HOST", "")
    if (
        os.environ.get("FUNCTIONS_EMULATOR") != "true"
        or host not in {"127.0.0.1:8080", "localhost:8080"}
    ):
        raise RuntimeError("로컬 Firestore 연결을 확인할 수 없습니다.")
    return host


def acquire_job(db, owner, scheduled_at):
    """작업 중 표시를 확보합니다. 이미 성공한 예약은 건너뜁니다."""
    job_ref = db.document(JOB_PATH)

    @firestore.transactional
    def acquire(transaction):
        state = job_ref.get(transaction=transaction).to_dict() or {}
        previous_time = state.get("lastSuccessfulScheduleTime")
        if scheduled_at is not None and previous_time is not None:
            if scheduled_at <= previous_time:
                return False

        now = datetime.now(timezone.utc)
        lease_until = state.get("leaseUntil")
        if state.get("lockOwner") and lease_until and lease_until > now:
            raise RuntimeError("다른 MVRV 수집이 실행 중입니다.")

        transaction.set(job_ref, {
            "lockOwner": owner,
            "leaseUntil": now + timedelta(seconds=LEASE_SECONDS),
            "status": "running",
            "lastStartedAt": firestore.SERVER_TIMESTAMP,
            "lastErrorCode": None,
        }, merge=True)
        return True

    return acquire(db.transaction())


def release_failed_job(db, owner, error_code):
    """실패한 자신의 잠금만 해제합니다."""
    job_ref = db.document(JOB_PATH)

    @firestore.transactional
    def release(transaction):
        state = job_ref.get(transaction=transaction).to_dict() or {}
        if state.get("lockOwner") != owner:
            return
        transaction.set(job_ref, {
            "lockOwner": None,
            "leaseUntil": datetime.now(timezone.utc),
            "status": "failed",
            "lastFailedAt": firestore.SERVER_TIMESTAMP,
            "lastErrorCode": error_code,
        }, merge=True)

    release(db.transaction())


def publish_history(db, history, owner, scheduled_at):
    """연도별 데이터와 latest, 성공 표시를 한꺼번에 저장합니다."""
    points = history["points"]
    grouped = {}
    for point in points:
        grouped.setdefault(int(point["t"][:4]), []).append(point)
    years = sorted(grouped)
    latest_ref = db.collection("mvrv_z_score").document("latest")
    job_ref = db.document(JOB_PATH)
    revision = uuid4().hex

    @firestore.transactional
    def publish(transaction):
        # 트랜잭션에서는 읽기를 모두 마친 다음 쓰기를 시작합니다.
        state = job_ref.get(transaction=transaction).to_dict() or {}
        previous = latest_ref.get(transaction=transaction).to_dict() or {}
        now = datetime.now(timezone.utc)
        if (state.get("lockOwner") != owner
                or state.get("leaseUntil", now) <= now):
            raise RuntimeError("작업 잠금이 만료되거나 소유자가 바뀌었습니다.")

        # 오래되거나 갑자기 짧아진 응답으로 기존 기록을 덮어쓰지 않습니다.
        if previous and not previous.get("isDemo", False):
            for field in ("asOf", "completeThrough"):
                if history[field] < previous.get(field, ""):
                    raise ValueError(f"기존 기록보다 오래된 {field}입니다.")
            if len(points) < previous.get("pointCount", 0):
                raise ValueError("기존 기록보다 데이터 건수가 줄었습니다.")
            if points[0]["t"] > previous.get("firstDate", points[0]["t"]):
                raise ValueError("과거 기록의 시작 부분이 누락되었습니다.")
            if points[-1]["t"] < previous.get("lastDate", points[-1]["t"]):
                raise ValueError("기존 기록의 마지막 날짜가 누락되었습니다.")

        for year in years:
            transaction.set(latest_ref.collection("years").document(str(year)), {
                "revision": revision,
                "series": grouped[year],
            })
        transaction.set(latest_ref, {
            "schemaVersion": 1,
            "source": history["source"],
            "isDemo": False,
            "asOf": history["asOf"],
            "completeThrough": history["completeThrough"],
            "collectedAt": firestore.SERVER_TIMESTAMP,
            "revision": revision,
            "years": years,
            "pointCount": len(points),
            "firstDate": points[0]["t"],
            "lastDate": points[-1]["t"],
        })
        success = {
            "lockOwner": None,
            "leaseUntil": now,
            "status": "succeeded",
            "lastSucceededAt": firestore.SERVER_TIMESTAMP,
            "lastErrorCode": None,
            "revision": revision,
        }
        if scheduled_at is not None:
            success["lastSuccessfulScheduleTime"] = scheduled_at
        transaction.set(job_ref, success, merge=True)

    publish(db.transaction())
    return {
        "ok": True,
        "status": "saved",
        "document": latest_ref.path,
        "asOf": history["asOf"],
        "completeThrough": history["completeThrough"],
        "pointCount": len(points),
        "firstDate": points[0]["t"],
        "lastDate": points[-1]["t"],
        "latestConfirmed": history["latestConfirmed"],
        "yearCounts": {str(year): len(grouped[year]) for year in years},
        "revision": revision,
    }


def run_mvrv_sync(scheduled_at=None):
    """로컬과 예약 함수가 함께 사용하는 실제 작업입니다."""
    db = firestore.client()
    if db.project != PROJECT_ID:
        raise RuntimeError("저장 대상 프로젝트가 btc-horizon-dev가 아닙니다.")
    owner = uuid4().hex
    if not acquire_job(db, owner, scheduled_at):
        return {"ok": True, "status": "already_completed"}

    try:
        history = fetch_mvrv_history()
        return publish_history(db, history, owner, scheduled_at)
    except Exception as error:
        try:
            release_failed_job(db, owner, type(error).__name__)
        except Exception:
            logger.error("MVRV_LOCK_RELEASE_FAILED")
        raise


# 예시 시간입니다. 실제 KOTE 갱신 시각 확인 후 조정합니다.
@scheduler_fn.on_schedule(
    schedule="0 15 * * *",      # 매일 오후 3시 정각에 실행
    timezone=scheduler_fn.Timezone("Asia/Seoul"),
    timeout_sec=120,            # 함수 실행 시간을 최대 120초로 설정
    secrets=["KOTE_API_KEY"],
    retry_count=1,              # 실패하면 재시도 1회 설정
    min_backoff_seconds=300,    # 실패 후 재시도까지 기다리는 최소 시간 5분
    max_backoff_seconds=300,    # 재시도 대기 시간의 상한도 5분
    max_retry_seconds=0,        # 재시도 기간을 별도로 늘리지 않고 횟수 제한 사용
)
def sync_mvrv_daily(event: scheduler_fn.ScheduledEvent) -> None:
    """배포 후 Cloud Scheduler가 한국 시간 오후 3시에 실행합니다."""
    if os.environ.get("FUNCTIONS_EMULATOR") == "true":
        require_local_firestore()
    elif os.environ.get("FIRESTORE_EMULATOR_HOST"):
        raise RuntimeError("클라우드 함수에 에뮬레이터 주소가 설정되어 있습니다.")
    try:
        result = run_mvrv_sync(event.schedule_time)
        logger.info("MVRV_SYNC_FINISHED", status=result["status"],
                    pointCount=result.get("pointCount"))
    except Exception as error:
        # 원본 응답/비밀키 대신 오류 종류만 기록합니다.
        logger.error("MVRV_SYNC_FAILED", errorType=type(error).__name__)
        # 실패로 끝내야 Scheduler가 정해진 횟수만큼 재시도합니다.
        raise RuntimeError(f"MVRV_SYNC_FAILED: {type(error).__name__}") from None


# 로컬 테스트 함수는 에뮬레이터에서만 등록합니다.
# 클라우드 배포 대상에는 sync_mvrv_daily만 나타납니다.
if os.environ.get("FUNCTIONS_EMULATOR") == "true":
    @https_fn.on_request(timeout_sec=120, secrets=["KOTE_API_KEY"])
    def sync_mvrv_local(req: https_fn.Request) -> https_fn.Response:
        try:
            host = require_local_firestore()
        except RuntimeError:
            return json_response({"ok": False, "message": "로컬 연결을 확인하세요."}, 403)
        if req.method != "POST":
            return json_response({"ok": False, "message": "POST 요청이 필요합니다."}, 405)
        try:
            result = run_mvrv_sync()
            result["firestoreHost"] = host
            return json_response(result)
        except Exception as error:
            logger.error("MVRV_LOCAL_FAILED", errorType=type(error).__name__)
            return json_response({
                "ok": False,
                "errorType": type(error).__name__,
                "message": "수집 또는 저장 실패. 기존 데이터는 유지됩니다.",
            }, 500)


