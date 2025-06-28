local fluxcdUtil = import 'fluxcd-util/main.jsonnet';

{
  app: fluxcdUtil.kustomizeFor('app', './generated/app'),
  auth: fluxcdUtil.kustomizeFor('auth', './generated/auth'),
  dashboard: fluxcdUtil.kustomizeFor('dashboard', './generated/dashboard'),
  database: fluxcdUtil.kustomizeFor('database', './generated/database'),
  game: fluxcdUtil.kustomizeFor('game', './generated/game'),
  media: fluxcdUtil.kustomizeFor('media', './generated/media'),
  network: fluxcdUtil.kustomizeFor('network', './generated/network'),
  o11y: fluxcdUtil.kustomizeFor('o11y', './generated/o11y'),
  storage: fluxcdUtil.kustomizeFor('storage', './generated/storage'),
}
