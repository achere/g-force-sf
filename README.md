# G-Force Salesforce Package

Installs a [Client Credentials-enabled Connected App](https://help.salesforce.com/s/articleView?id=sf.connected_app_client_credentials_setup.htm&type=5)
and a Lightning App that walks you through setting up a connection to a GitLab instance and create a CI/CD file variable
that contains authentication information for the org the package is installed in. The variable then can be used to
authenticate [apexcov](https://github.com/achere/g-force/releases) in a CI/CD pipeline. Works only with sandbox, scratch
and Developer Edition orgs.

## Installation

### Via the Browser

1. While authenticated in your org (sandbox or scratch), navigate to the [installation URL](https://login.salesforce.com/packaging/installPackage.apexp?p0=04tQy0000001dNVIAY)
   and follow the instructions there.
1. In the Setup UI, assign the G-Force permission set to your user.

### Via the Command Line

1. Login to your org using [any preferred method](https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/sfdx_dev/sfdx_dev_auth.htm),
   setting it as your default (`-s` flag). If you don't make it default, append `-o <your_org_alias>` to the following commands
1. While authenticated to your org, run

```shell
sf package install -p G-Force@0.2.0-1 -w 5
```

1. Assign the permission set with

```shell
sf org assign permset -n gfrc__G_Force
```

## Usage

Once the permission set is assigned, you get access to the G-Force Lightning App. Open the app and follow the
instructions there to connect to your Gitlab project and share the authentication information for your org with Gitlab.

The proposed workflow for using `apexcov` with Gitlab CI/CD is to associate branches with environments. During the
package configuration, the user is presented with a list of branches from the project they selected. When the steps
in the package are complete, it creates a CI/CD variable `APEXCOV_CONFIG` of type file with environment set to the name
of the branch. The `APEXCOV_CONFIG` variable contains a JSON with auth info for the org suitable for passing to the
`-config` flag of the `apexcov` CLI. Creating this variable for the branch is called "claiming the branch".

> [!NOTE]
> Protected branches and those that already have an `APEXCOV_CONFIG` variable associated with them, don't show up in the
> list of branches available to be "claimed".
