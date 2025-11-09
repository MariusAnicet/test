class DomainError(Exception):
    """Erreur générique du domaine métier."""
    pass


class ValidationError(DomainError):
    """Entrée invalide vis-à-vis des règles métier."""
    pass


class NotOwnerError(DomainError):
    """Tentative d'action par un utilisateur non propriétaire."""
    pass
