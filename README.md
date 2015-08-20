# How to use this image

```console
$ docker run --name some-magento --link some-mysql:mysql -d magento
```

## Environment variables
Make sure your mysql container exports the following environment variables:

-	`MYSQL_ROOT_PASSWORD`
-	`MYSQL_DATABASE`
-	`MYSQL_USER`
-	`MYSQL_PASSWORD`

The following environment variables need to be set to configure your magento instance:

-	`MAGENTO_URL`: the public URL magento will be reachable on (for example `http://www.some-magento.com` or `http://localhost:8080`)
-	`MAGENTO_ADMIN_PASSWORD`: the password for the account `admin`
-	`MAGENTO_ADMIN_PASSWORD`: an optional prefix for the database tables.

## Using an existing installation
To make your shop persistent or if you already have a magento installation, set a volume:
`-v $(pwd)/magento:/var/www/html`

If the directory is empty, a fresh Magento installation will be copied into it.

When running a fresh installation, the entrypoint script will not modify the database, because it first needs to be initialized by the Magento wizard. The settings (like URL and admin password) will be set in the database if you use an existing shop (i.e. a non-empty /var/www/html volume)

## Save parts of the DB in your VCS

Almost everything you can set in the Magento admin console will be saved to the database. This makes it very hard to reconcile changes made in production (such as sales, logs, etc.) and changes you want to do the development environment first. (As an example, in our case, we keep our product catalog checked into git, but not the inventory data)

To make it easy to check parts of your settings or data into your version control, you can dump certain tables into sql files from a running container:

```console
$ docker exec some-magento create-patches
```

The selected tables will then be dumped to `/sql/patches`, so make sure you use a volume:
`-v $(pwd)/sql:/sql`

To select the tables you want to dump, edit `/sql/sql_tables` and comment in all the tables you need. Since this file is inside a volume, you can also easily check it in to version control with the patches. However, if you delete it, the default file will be restored with default tables setting when you re-run the image.
At this point these are just the tables we have identified as reasonable to save so far. Feel free to suggest any changes, if you see something that absolutely does not make sense. The idea is to separate configuration from live data.

The sql files in `/sql/patches/` will always be executed when you run the image.
You can also provide a complete SQL dump in `/sql/`, which will be loaded first. This allows having a working default db state (say, just after initializing the shop) which you don't need to update anymore, and then just saving all the following changes in with the `create-patches` command.

For example, in one project of ours, /sql looks like this:
```
sql/
├── initial_shop.sql        <-- This is a complete dump, created after finishing the Magento wizard
├── patches
│   ├── api2_acl_role.sql
│   ├── api2_acl_rule.sql
│   ├── api2_acl_user.sql
│   ├── api_role.sql
│   ├── api_rule.sql
│   ...
└── sql_tables
```

We then change something in the admin ui, run create-patches, and git commit.

## Compose

Here is an example docker-compose file:
```
somemagento:
        image: latupo/magento
        volumes:
                - mage:/var/www/html
                - sql:/sql
        ports:
                - "8080:80"
        links:
                - somemysql:mysql
        environment:
                MAGENTO_URL: "http://192.168.59.103:8080"
                MAGENTO_ADMIN_PASSWORD: theAdminPassword

somemysql:
        image: mysql
        environment:
                # set mysql credentials. These will be created once with the container and kept
                # in the volume along with the data.
                MYSQL_ROOT_PASSWORD: theSqlPassword
                MYSQL_DATABASE: theDatabaseName
                MYSQL_USER: magentoUser
                MYSQL_PASSWORD: theMagentoUserPassword
```
