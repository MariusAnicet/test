from dataclasses import dataclass
from typing import Generic, List, TypeVar, Optional

T = TypeVar("T")


@dataclass
class Page(Generic[T]):
    """Structure de pagination simple pour les listes d'entités."""
    items: List[T]
    total: int
    limit: int
    offset: int
    next_offset: Optional[int] = None

    @staticmethod
    def from_items(items: List[T], total: int, limit: int, offset: int) -> "Page[T]":
        next_off = offset + limit if offset + limit < total else None
        return Page(items=items, total=total, limit=limit, offset=offset, next_offset=next_off)
