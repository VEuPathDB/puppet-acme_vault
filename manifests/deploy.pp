# acme_vault::deploy
#
# This class configures the deployment of certificates from HashiCorp Vault
# to the filesystem. It sets up the necessary directory structure, scripts,
# and cron jobs to periodically check for and deploy updated certificates
# for the specified domains.
#
# @param user The system user for the acme_vault module.
# @param group The system group for the acme_vault module.
# @param home_dir The home directory for the acme_vault user.
# @param domains The list of domain names for which certificates will be deployed.
#
# @param cert_destination_path The directory where certificates will be deployed on the filesystem.
# @param deploy_scripts The directory where deployment scripts will be stored.
# @param restart_method The command to run after certificate deployment (e.g., to restart dependent services).
#
class acme_vault::deploy(
    $user                  = $::acme_vault::common::user,
    $group                 = $::acme_vault::common::group,
    $home_dir              = $::acme_vault::common::home_dir,
    $domains               = $::acme_vault::common::domains,

    $cert_destination_path = $::acme_vault::params::cert_destination_path,
    $deploy_scripts        = $::acme_vault::params::deploy_scripts,
    $restart_method        = $::acme_vault::params::restart_method,

) inherits acme_vault::params {
  include acme_vault::common

  # copy down cert check script
  file {"${home_dir}/check_cert.sh":
    ensure => present,
    owner  => $user,
    group  => $group,
    mode   => '0750',
    source => 'puppet:///modules/acme_vault/check_cert.sh',
  }

  # ensure destination paths exist
  file {[$cert_destination_path, $deploy_scripts]:
    ensure => directory,
    owner  => $user,
    group  => $group,
    mode   => '0750',
  }

  # go through each domain, setup cron, and ensure the destination dir exists
  $domains.each |$domain, $d_list| {
    cron { "${domain}_deploy":
      command => ". \$HOME/.bashrc && ${home_dir}/check_cert.sh ${domain} ${cert_destination_path} && ${restart_method}",
      user    => $user,
      weekday => ['2-4'],
      hour    => ['11-16'],
      minute  => 30,
    }

    file {"${cert_destination_path}/${domain}":
      ensure => directory,
      owner  => $user,
      group  => $group,
      mode   => '0750',
    }
  }

}


