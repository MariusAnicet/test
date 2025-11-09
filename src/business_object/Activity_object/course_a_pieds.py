from dataclasses import dataclass
from .abstract_activity import Activite
from ..base_types import Sport


@dataclass
class CourseAPieds(Activite):
    """Spécifique course à pieds : expose le pace min/km."""
    sport: Sport = Sport.RUNNING  # par défaut

    def pace_s_par_km(self) -> float | None:
        """Temps moyen par km (en secondes), None si distance nulle."""
        if self.distance_m > 0:
            return self.duration_s / (self.distance_m / 1000.0)
        return None

    def pace_min_km(self) -> str | None:
        """Pace formaté 'mm:ss /km'."""
        ps = self.pace_s_par_km()
        if ps is None:
            return None
        m = int(ps // 60)
        s = int(round(ps % 60))
        return f"{m:02d}:{s:02d} /km"
