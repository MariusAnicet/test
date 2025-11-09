from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime
from math import radians, sin, cos, atan2, sqrt
from typing import List, Optional

from .track_point import TrackPoint


@dataclass
class GPXTrace:
    """Value object représentant une trace GPX (liste ordonnée de points)."""
    points: List[TrackPoint]

    def is_empty(self) -> bool:
        return len(self.points) == 0

    def start_time(self) -> Optional[datetime]:
        return self.points[0].time if self.points else None

    def end_time(self) -> Optional[datetime]:
        return self.points[-1].time if self.points else None

    def duree_seconds(self) -> int:
        if self.is_empty():
            return 0
        return int((self.end_time() - self.start_time()).total_seconds())

    def distance_totale_m(self) -> int:
        """Somme des distances Haversine entre points (en mètres)."""
        dist = 0.0
        for p1, p2 in zip(self.points, self.points[1:]):
            dist += self._haversine_m(p1.lat, p1.lon, p2.lat, p2.lon)
        return int(round(dist))

    def denivele_positif_m(self) -> int:
        """Somme des dénivelés positifs (m)."""
        gain = 0.0
        prev_ele = None
        for p in self.points:
            if p.ele is not None and prev_ele is not None:
                diff = p.ele - prev_ele
                if diff > 0:
                    gain += diff
            prev_ele = p.ele if p.ele is not None else prev_ele
        return int(round(gain))

    # ----- utilitaires -----

    @staticmethod
    def _haversine_m(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
        """Distance Haversine en mètres."""
        R = 6371000.0  # rayon moyen Terre en m
        f1, f2 = radians(lat1), radians(lat2)
        d_f = radians(lat2 - lat1)
        d_l = radians(lon2 - lon1)
        a = sin(d_f / 2) ** 2 + cos(f1) * cos(f2) * sin(d_l / 2) ** 2
        c = 2 * atan2(sqrt(a), sqrt(1 - a))
        return R * c
