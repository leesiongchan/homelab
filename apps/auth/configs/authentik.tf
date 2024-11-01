terraform {
  required_providers {
    authentik = {
      source  = "goauthentik/authentik"
      version = "2024.8.4"
    }
  }
}

variable "token" {
  type = string
  sensitive = true
}

provider "authentik" {
  url   = "https://authentik-server.auth.svc.cluster.local"
  token = var.token
  insecure = true
}

data "authentik_flow" "default-provider-authorization-implicit-consent" {
  slug = "default-provider-authorization-implicit-consent"
}
data "authentik_property_mapping_provider_scope" "scope-email" {
  name = "authentik default OAuth Mapping: OpenID 'email'"
}
data "authentik_property_mapping_provider_scope" "scope-profile" {
  name = "authentik default OAuth Mapping: OpenID 'profile'"
}
data "authentik_property_mapping_provider_scope" "scope-openid" {
  name = "authentik default OAuth Mapping: OpenID 'openid'"
}

resource "authentik_provider_oauth2" "generic_oauth" {
  name          = "Generic OAuth"

  authorization_flow  = data.authentik_flow.default-provider-authorization-implicit-consent.id
  client_id     = "28f1f204fc23afa9e85625a07651ca9f"
  property_mappings = [
    data.authentik_property_mapping_provider_scope.scope-email.id,
    data.authentik_property_mapping_provider_scope.scope-openid.id,
    data.authentik_property_mapping_provider_scope.scope-profile.id
  ]
  redirect_uris = [
    "https://flix.o5s.lol/sso/OID/redirect/generic_oauth",
    "https://flux.o5s.lol/oauth2/callback",
    "https://o11y.o5s.lol/login/generic_oauth",
    "https://portainer.o5s.lol",
  ]
}
resource "authentik_application" "generic_oauth" {
  name              = "Generic OAuth"

  slug              = "generic_oauth"
  protocol_provider = authentik_provider_oauth2.generic_oauth.id
}

output "authentik_generic_oauth_client_id" {
  value = authentik_provider_oauth2.generic_oauth.client_id
}
output "authentik_generic_oauth_client_secret" {
  value = authentik_provider_oauth2.generic_oauth.client_secret
  sensitive = true
}
