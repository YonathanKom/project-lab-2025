from pydantic import BaseModel
from typing import Any, List, Optional


class ResponseMessage(BaseModel):
    message: str
    success: bool = True


class ErrorResponse(BaseModel):
    detail: str
    error_code: Optional[str] = None


class PaginationParams(BaseModel):
    skip: int = 0
    limit: int = 50


class PaginatedResponse(BaseModel):
    items: List[Any]
    total: int
    skip: int
    limit: int
    has_more: bool


class BulkOperationResult(BaseModel):
    success_count: int
    error_count: int
    errors: List[str] = []
    created_ids: List[int] = []
