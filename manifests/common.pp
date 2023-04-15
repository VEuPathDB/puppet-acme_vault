# acme_vault::common
#
# This class defines the common configuration for the acme_vault module.
# It sets up the necessary user, group, home directory, and environment
# variables for the acme_vault module to interact with Let's Encrypt and
# HashiCorp Vault for certificate management.
#
# @param user The system user for the acme_vault module.
# @param group The system group for the acme_vault module.
# @param group_members Additional group members that require access to the certificates.
# @param home_dir The home directory for the acme_vault user.
# @param contact_email The email address for Let's Encrypt registration and notifications.
# @param domains The list of domain names to request certificates for.
# @param overrides A hash of domain-specific configuration overrides.
#
# @param vault_token The authentication token for accessing HashiCorp Vault.
# @param vault_addr The address of the HashiCorp Vault server.
# @param vault_bin The path to the Vault binary.
# @param vault_prefix The prefix for storing certificates in Vault.
#
class acme_vault::common (
    $user               = $::acme_vault::params::user,
    $group              = $::acme_vault::params::group,
    $group_members      = $::acme_vault::params::group_members,
    $home_dir           = $::acme_vault::params::home_dir,
    $contact_email      = $::acme_vault::params::contact_email,
    $domains            = $::acme_vault::params::domains,
    $overrides          = $::acme_vault::params::overrides,

    $vault_token        = $::acme_vault::params::vault_token,
    $vault_addr         = $::acme_vault::params::vault_addr,
    $vault_bin          = $::acme_vault::params::vault_bin,
    $vault_prefix       = $::acme_vault::params::vault_prefix,

) inherits acme_vault::params {

    $common_bashrc_template = @(END)
    export PATH=$HOME:$PATH
    export VAULT_CMD=<%= @vault_bin %>
    export VAULT_TOKEN=<%= @vault_token %>
    export VAULT_ADDR=<%= @vault_addr %>
    export VAULT_PREFIX=<%= @vault_prefix %>
    | END

    # create acme_vault user
    user { $user:
      ensure     => present,
      gid        => $group,
      system     => true,
      home       => $home_dir,
      managehome => true,
    }

    file { $home_dir:
      ensure => directory,
      owner  => $user,
      group  => $group,
      mode   => '0750',
    }

    # group membership is handled through collected virtual resources.  This
    # allows other modules/profiles to add members to the group, for services
    # that require access to the certs

    @group { $group:
      ensure => present,
      system => true,
      tag    => 'acme_vault_group',
    }

    # include lines similar to this in your own modules to add members to the
    # group.  We use this method here to add the group_members paramater, but
    # it will work the same in any module.

    Group <| tag == 'acme_vault_group' |> { members +> $group_members }

    # variables in bashrc
    concat { "${home_dir}/.bashrc":
      owner => $user,
      group => $group,
      mode  => '0600',
    }

    concat::fragment{ 'vault_bashrc':
      target  => "${home_dir}/.bashrc",
      content => inline_template($common_bashrc_template),
      order   => '01',
    }

    # common dummy cron job to set MAILTO
    cron { 'dummy_mailto':
      command     => '/bin/true',
      user        => $user,
      month       => 7,
      hour        => 1,
      minute      => 29,
      environment => "MAILTO=${contact_email}",
    }

    # renew vault token
    cron { 'renew vault token':
      command => ". \$HOME/.bashrc && ${vault_bin} token renew > /dev/null",
      user    => $user,
      weekday => 1,
      hour    => 10,
      minute  => 17,
    }

}
