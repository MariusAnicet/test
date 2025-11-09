from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime
from typing import Optional, List, Tuple, Any

from .base_types import Sport


@dataclass(frozen=True)
class FiltreActivite:
    """
    Value object décrivant des critères de filtrage.
    NOTE: La conversion en SQL est fournie pour aider la couche DAO (SQL pur).
    """
    sport: Optional[Sport] = None
    date_debut: Optional[datetime] = None
    date_fin: Optional[datetime] = None
    distance_min: Optional[int] = None
    distance_max: Optional[int] = None
    duree_min: Optional[int] = None
    duree_max: Optional[int] = None
    texte: Optional[str] = None  # recherche simple sur titre/description

    def to_sql_where_params(self, user_id: int) -> Tuple[str, List[Any]]:
        """
        Construit WHERE + params pour une recherche dans `activite`.
        N'ajoute pas LIMIT/OFFSET. Filtre toujours sur user_id et deleted_at IS NULL.
        """
        clauses = ["user_id = %s", "deleted_at IS NULL"]
        params: List[Any] = [user_id]

        if self.sport is not None:
            clauses.append("sport = %s")
            params.append(self.sport.value)

        if self.date_debut is not None:
            clauses.append("start_time >= %s")
            params.append(self.date_debut)

        if self.date_fin is not None:
            clauses.append("start_time <= %s")
            params.append(self.date_fin)

        if self.distance_min is not None:
            clauses.append("distance_m >= %s")
            params.append(self.distance_min)

        if self.distance_max is not None:
            clauses.append("distance_m <= %s")
            params.append(self.distance_max)

        if self.duree_min is not None:
            clauses.append("duration_s >= %s")
            params.append(self.duree_min)

        if self.duree_max is not None:
            clauses.append("duration_s <= %s")
            params.append(self.duree_max)

        if self.texte:
            # recherche naïve sur titre/description
            clauses.append("(titre ILIKE %s OR description ILIKE %s)")
            like = f"%{self.texte}%"
            params.extend([like, like])

        where = " WHERE " + " AND ".join(clauses)
        return where, params
