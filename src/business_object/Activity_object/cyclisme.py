from dataclasses import dataclass
from .abstract_activity import Activite
from ..base_types import Sport


@dataclass
class Cyclisme(Activite):
    """Spécifique cyclisme. On peut ajouter des helpers cadence, W', etc."""
    sport: Sport = Sport.CYCLING

    # Exemples de helpers supplémentaires possibles :
    # def normalized_power(self) -> Optional[float]: ...
