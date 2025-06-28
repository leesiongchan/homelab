local fluxcdUtil = import 'fluxcd-util/main.jsonnet';

{
  app: fluxcdUtil.kustomizeFor('app', 'app', './generated/app'),
  auth: fluxcdUtil.kustomizeFor('auth', 'auth', './generated/auth'),
  database: fluxcdUtil.kustomizeFor('database', 'database', './generated/database'),
  dashboard: fluxcdUtil.kustomizeFor('dashboard', 'dashboard', './generated/dashboard'),
  game: fluxcdUtil.kustomizeFor('game', 'game', './generated/game'),
}
