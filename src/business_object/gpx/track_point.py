from dataclasses import dataclass
from datetime import datetime
from typing import Optional


@dataclass(frozen=True)
class TrackPoint:
    """Point de trace GPX minimal."""
    time: datetime
    lat: float
    lon: float
    ele: Optional[float] = None
    hr: Optional[int] = None   # fréquence cardiaque
    cad: Optional[int] = None  # cadence
