from dataclasses import dataclass
from .abstract_activity import Activite
from ..base_types import Sport


@dataclass
class Randonnee(Activite):
    """Spécifique randonnée (vitesse de marche, dénivelé/heure, etc.)."""
    sport: Sport = Sport.HIKING

    def vitesse_marche_kmh(self) -> float | None:
        """Vitesse moyenne de marche (km/h)."""
        if self.duration_s > 0:
            return (self.distance_m / 1000.0) / (self.duration_s / 3600.0)
        return None
