from typing import Type
from .base_types import Sport
from .Activity_object.abstract_activity import Activite
from .Activity_object.course_a_pieds import CourseAPieds
from .Activity_object.cyclisme import Cyclisme
from .Activity_object.randonnee import Randonnee
from .Activity_object.natation import Natation


class ActivityFactory:
    """Fabrique d'activités pour instancier la bonne sous-classe selon le sport."""

    _MAP: dict[Sport, Type[Activite]] = {
        Sport.RUNNING: CourseAPieds,
        Sport.CYCLING: Cyclisme,
        Sport.HIKING: Randonnee,
        Sport.SWIMMING: Natation,
    }

    @classmethod
    def create(cls, sport: Sport, **kwargs) -> Activite:
        klass = cls._MAP.get(sport)
        if not klass:
            raise ValueError(f"Sport non géré: {sport}")
        return klass(sport=sport, **kwargs)
