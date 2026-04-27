from fastapi import APIRouter
from fastapi.responses import JSONResponse
from pydantic import BaseModel
from app.services.email_service import send_otp, verify_otp

router = APIRouter()


class SendOtpRequest(BaseModel):
    email: str
    is_password_reset: bool = False


class VerifyOtpRequest(BaseModel):
    email: str
    code: str


@router.post("/send-otp")
def send_otp_endpoint(payload: SendOtpRequest):
    try:
        send_otp(payload.email, is_password_reset=payload.is_password_reset)
        return JSONResponse({"success": True})
    except Exception as e:
        return JSONResponse(status_code=500, content={"detail": str(e)})


@router.post("/verify-otp")
def verify_otp_endpoint(payload: VerifyOtpRequest):
    valid = verify_otp(payload.email, payload.code)
    return JSONResponse({"valid": valid})
