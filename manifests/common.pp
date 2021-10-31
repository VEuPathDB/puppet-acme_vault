# Common configuration for acme_vault
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
    export VAULT_BIN=<%= @vault_bin %>
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
      ensure  => present,
      system  => true,
      tag     => 'acme_vault_group',
    }

    # include lines similar to this in your own modules to add members to the
    # group.  We use this method here to add the group_members paramater, but
    # it will work the same in any module.

    Group <| tag == 'acme_vault_group' |> { members +> $group_members }

    # vault module isn't too flexible for install only, just copy in binary
    # would be nice if this worked!
    #class { '::vault::install':
    #  manage_user => false,
    #}
    #
    # we have moved to installing vault binary via a dedicated profile, we no
    # longer what this here.  This can be removed after puppet cleans up.

    file { $vault_bin:
        ensure => absent,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/acme_vault/vault',
    }

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
      command => ". \$HOME/.bashrc && $vault_bin token-renew > /dev/null",
      user    => $user,
      weekday => 1,
      hour    => 10,
      minute  => 17,
    }

}

