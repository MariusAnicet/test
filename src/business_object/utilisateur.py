from dataclasses import dataclass, field
from datetime import datetime, timezone
from typing import Optional

from .errors import NotOwnerError
from .Activity_object.abstract_activity import Activite


@dataclass
class Utilisateur:
    """Entité Utilisateur (métier, sans persistance)."""
    id: Optional[int]
    username: str
    email: str
    password_hash: str
    created_at: datetime = field(default_factory=lambda: datetime.now(timezone.utc))
    updated_at: datetime = field(default_factory=lambda: datetime.now(timezone.utc))

    def peut_modifier(self, activite: Activite) -> bool:
        """Vrai si l'utilisateur est propriétaire de l'activité."""
        return activite.user_id == self.id

    def assert_peut_modifier(self, activite: Activite) -> None:
        if not self.peut_modifier(activite):
            raise NotOwnerError("Cet utilisateur n'est pas propriétaire de l'activité.")

    def changer_mot_de_passe(self, nouveau_hash: str) -> None:
        self.password_hash = nouveau_hash
        self.updated_at = datetime.now(timezone.utc)
