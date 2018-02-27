class acme_vault::common (
    $user               = $::acme_vault::params::user,
    $group              = $::acme_vault::params::group,
    $home_dir           = $::acme_vault::params::home_dir,
    $domains            = $::acme_vault::params::domains,
    $contact_email      = $::acme_vault::params::contact_email,

    $vault_token        = $::acme_vault::params::vault_token,
    $vault_addr         = $::acme_vault::params::vault_addr,
    $vault_bin          = $::acme_vault::params::vault_bin,
    $vault_prefix       = $::acme_vault::params::vault_prefix,

) inherits acme_vault::params {

    $common_bashrc_template = @(END)
export VAULT_BIN=<%= @vault_bin %>
export VAULT_TOKEN=<%= @vault_token %>
export VAULT_ADDR=<%= @vault_addr %>
export VAULT_PREFIX=<%= @vault_prefix %>
END
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

    # vault module isn't too flexible for install only, just copy in binary
    # would be nice if this worked!
    #class { '::vault::install':
    #  manage_user => false,
    #}

    file { $vault_bin:
        ensure => present,
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
      environment => "MAILTO=${contact_email}",
    }

    #		file { "$home_dir/.bashrc":
    #			ensure  => present,
    #			owner   => $user,
    #      group   => $group,
    #      mode    => "0600",
    #      content => template("acme_vault/bashrc"),
    #    }


}
