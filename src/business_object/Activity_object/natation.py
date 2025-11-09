from dataclasses import dataclass
from .abstract_activity import Activite
from ..base_types import Sport


@dataclass
class Natation(Activite):
    """Spécifique natation : expose le pace /100m."""
    sport: Sport = Sport.SWIMMING

    def pace_s_par_100m(self) -> float | None:
        if self.distance_m > 0:
            return self.duration_s / (self.distance_m / 100.0)
        return None

    def pace_min_100m(self) -> str | None:
        ps = self.pace_s_par_100m()
        if ps is None:
            return None
        m = int(ps // 60)
        s = int(round(ps % 60))
        return f"{m:02d}:{s:02d} /100m"
