# Drone GitHub App Secrets

Use `create-drone-gh-app-secrets.sh` to add GitHub App secrets to a Drone repository.

## Prequisites & Keybase

You can find the values for the required secrets in Keybase. The secrets are kept in the `github-app-secrets.txt` file. 

Create a github-actions-secrets.env file, in this folder, with the values from the keybase file. 

Create 2 local `.pem` files for each of the private key entries in the same directory as this script;

- `ukho_gh_app.pem`
- `hof_gh_app.pem`

### Drone Details

See [secret guidelines](https://collaboration.homeoffice.gov.uk/spaces/DSASS/pages/339158739/Secrets+Creation+Guidelines) for details on the DRONE_SERVER address. 

You can find your own DRONE_TOKEN on your drone profile: 
1. Go into Drone UI
2. Click profile in bottom left corner
3. Copy 'Personal Token'

## Required Files

Keep these files in the same directory as the script:

- `create-drone-gh-app-secrets.sh`
- your secrets env file, for example `github-actions-secrets.env`
- `ukho_gh_app.pem`
- `hof_gh_app.pem`

The env file should contain one secret per line:

```env
SECRET_NAME=secret-value
ANOTHER_SECRET=another-secret-value
```

Blank lines and lines starting with `#` are ignored.

## Usage

```bash
./drone-gh-app-secrets.sh <drone-server> <drone-token> <org/repo> <secrets.env>
```

Example:

```bash
./drone-gh-app-secrets.sh \
  https://drone.example.gov.uk/ \
  your-drone-token \
  my-org/my-repo \
  github-actions-secrets.env
```

## Arguments

- `<drone-server>`: Drone server URL.
- `<drone-token>`: Drone API token for a user with access to the repository.
- `<org/repo>`: Target repository, for example `my-org/my-repo`.
- `<secrets.env>`: Name of the env file in the same directory as the script.

The script does not store the Drone server or token. Pass them in each time you run it.
