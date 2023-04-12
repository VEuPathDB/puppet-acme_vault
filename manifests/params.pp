# acme_vault::params
#
# This class defines the default parameters for the acme_vault module.
# It includes settings for the acme user, authentication, staging and production URLs,
# repository paths, Namecheap configuration, and deployment settings.
#
# @param user The system user for the acme_vault module.
# @param group The system group for the acme_vault module.
# @param group_members Members of the acme_vault group.
# @param home_dir The home directory for the acme_vault user.
# @param contact_email The contact email address for Let's Encrypt notifications.
# @param domains The list of domain names for which certificates will be requested and managed.
# @param overrides A list of challenge-alias overrides. Defaults to the domain itself.
#
# @param vault_token HashiCorp Vault authentication token.
# @param vault_addr HashiCorp Vault server address.
# @param vault_bin Path to the HashiCorp Vault binary.
# @param vault_prefix The path prefix in Vault where Let's Encrypt secrets are stored.
#
# @param staging Whether to use the Let's Encrypt staging environment.
# @param staging_url Let's Encrypt staging environment API URL.
# @param prod_url Let's Encrypt production environment API URL.
#
# @param acme_revision The revision of the acme.sh script to use.
# @param acme_repo_path The path to the acme.sh repository.
# @param acme_script The path to the acme.sh script within the repository.
#
# @param namecheap_username Namecheap account username for DNS API.
# @param namecheap_api_key Namecheap API key.
# @param namecheap_sourceip The source IP address for Namecheap API requests.
#
# @param cert_destination_path The directory where certificates will be deployed on the filesystem.
# @param deploy_scripts The directory where deployment scripts will be stored.
# @param restart_method The command to run after certificate deployment (e.g., to restart dependent services).
#
class acme_vault::params {
    # settings for acme user
    $user           = 'acme'
    $group          = 'acme'
    $group_members  = []
    $home_dir       = '/home/acme_vault'
    $contact_email  = ''
    $domains        = undef
    # overrides is a list of challenge-alias overrides.  It defaults to the domain itself.
    # see https://github.com/Neilpang/acme.sh/wiki/DNS-alias-mode
    $overrides      = {}

    # authentication
    $vault_token    = undef
    $vault_addr     = undef
    $vault_bin      = '/usr/local/bin/vault'

    $vault_prefix   = '/secret/letsencrypt/'

    # whether to use the letsencrypt staging url, set those urls
    $staging        = false
    $staging_url    = 'https://acme-staging-v02.api.letsencrypt.org/directory'
    $prod_url       = 'https://acme-v02.api.letsencrypt.org/directory'

    $acme_revision  = 'HEAD'
    $acme_repo_path = "${home_dir}/acme.sh"
    $acme_script    = "${acme_repo_path}/acme.sh"

    # namecheap
    $namecheap_username = undef
    $namecheap_api_key  = undef
    $namecheap_sourceip = '127.0.0.1'

    # settings for deploy
    $cert_destination_path = '/etc/acme'
    $deploy_scripts        = "${cert_destination_path}/deploy.d"
    $restart_method        = "for f in ${deploy_scripts}/*.sh; do \"\$f\"; done"
}
