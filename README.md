# Moria Overviewer Automation

Automation scripts for generating a world map viewer using Minecraft Overviewer.

## Dependencies

We are using a Windows 10 PC to generate the map viewer as it will have a larger drive capacity and faster CPU than a Raspberry Pi, although the `generate-map.ps1` PowerShell script could probably be ported to Node.js for similar functionality if you wanted it to run on a Pi.

* Windows 10
* Minecraft Java Edition
* Tiny Task (https://www.tinytask.net/)
* Minecraft overviewer 0.13 or higher (https://overviewer.org/downloads)
* AWS CLI (https://s3.amazonaws.com/aws-cli/AWSCLI64PY3.msi)

## Installation

### Install Dependencies
1. Install [Minecraft Java Edition](https://www.minecraft.net/)
2. Install [Tiny Task](https://www.tinytask.net/)

### Configure AWS
1. Install AWS ClI
2. Login to the AWS console
3. Create an S3 bucket.
4. Create a public folder in the bucket called `map` with the following permissions:
```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "PublicReadGetObject",
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::BUCKETNAME/*"
        }
    ]
}
```
Where `BUCKETNAME` is the name of the S3 bucket you have created.
5. Create an [IAM user](https://console.aws.amazon.com/iam/home?region=ap-southeast-2#/users) with the following policy:
```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "Stmt1397834652000",
            "Effect": "Allow",
            "Action": [
                "s3:ListAllMyBuckets"
            ],
            "Resource": [
                "arn:aws:s3:::*"
            ]
        },
        {
            "Sid": "Stmt1397834745000",
            "Effect": "Allow",
            "Action": [
                "s3:ListBucket",
                "s3:PutObject",
                "s3:PutObjectAcl",
                "s3:DeleteObject",
                "s3:DeleteObjectVersion",
                "s3:PutLifeCycleConfiguration"
            ],
            "Resource": [
                "arn:aws:s3:::BUCKETNAME*",
                "arn:aws:s3:::BUCKETNAME/*"
            ]
        }
    ]
}
```
Where `BUCKETNAME` is the name of the S3 bucket you have created.
6. Create security credentials for the IAM user and remember the Access Key ID and Secret.
7. Run `aws configure` and enter your IAM credentials for your account and enter the following details:
    * Access Key ID: `ACCESS_KEY`
    * Secret: `SECRET`
    * Region: `ap-southeast-2` (or your equivalent region)
    * Format: `json`

### Configure Minecraft Overviewer
1. Run Minecraft Java Edition and log into your account  with admin privilages for your Minecraft Realm.
2. Close Minecraft
3. Follow the Minecraft Overviewer [installation instructions](http://docs.overviewer.org/en/latest/installing/#windows)
4. Create a folder with the following structure in your Documents folder:
    * `java-map-gen`
        * `automation`
        * `logs`
        * `out`
        * `overviewer`
5. Unzip Minecraft Overviewer into `overviewer` folder.
6. Clone this git repository into the `automation` folder.
7. Copy the contents of `automation/icons` folder into `overviewer/overviewer_core/data/web_assets/icons`. This will add the custom icons for the villager professions. 

### Configure Automation
1. Run Tiny Task and record a macro of the process for opening Minecraft and downloading a backup from Minecraft Realms.
    * Run Tiny Task
    * Press `ALT + CTRL + SHIFT + R` to start macro recording.
    * Press `Windows + S` and type 'Minecraft Launcher' and press `ENTER`.
    * Press `Windows + UP Key` to maximise the Minecraft Launcher.
    * Click the *Launch* button.
    * Wait 30 seconds (this is to allow the macro enough time to patch and start Minecraft).
    * Press `Windows + UP Key` to maximise Minecraft.
    * Click the *Minecraft Realms* button.
    * Click the *Configure realm* button.
    * Click the *World backups* button.
    * Click the *Download latest* button.
    * Wait 15 minutes (this is to allow the backup enough time to download).
    * Press `ALT + F4` to close Minecraft.
    * Press `ALT + CTRL + SHIFT + R` to end macro recording.
    * Click the *Save EXE* button and select the `automation` folder. Call the filename `backup-macro.exe`.

### Configure Scheduling
1. Open *PowerShell* as an Administrator and type the following command: `Set-ExecutionPolicy RemoteSigned`.
2. Close *PowerShell*.
3. Open *Task Scheduler*.
4. Click *Create Task*
5. Enter the following details:
    * Name: Backup and Generate Minecraft Map
    * Description: Connect to Realms, downloads backup to local Minecraft directory and runs Overviewer to generate map based on it, then syncs this to Amazon S3.
    * Run only when user is logged in.
6. Add a trigger:
    * Begin the task: On a schedule
    * Daily
    * Start: (use the current date) and set the desired time
    * Recur every: 1 days
    * Stop task if it runs longer than 6 hours (optional)
    * Enabled: true
7. Add an action:
    * Action: Start a program
    * Program/script: `%SystemRoot%\system32\WindowsPowerShell\v1.0\powershell.exe`
    * Add arguments: `C:\Users\USERNAME\Documents\java-map-gen\automation\generate-map.ps1` where `USERNAME` is the name of your user where the `java-map-gen` folder is.
8. Set conditions:
    * Start the task only if the computer is on AC power: true
    * Stop if the computer switches to battery power: true
9. Set settings:
    * Allow the task to be run on demand: true
    * Stop the task if it runs longer than: 3 days
    * If the running task does not end when requested, force it to stop: true
    * If the task is already running, then the following rule applies: Do not start a new instance
10. Save the task.

## Viewing

The map will be accessible at: https://s3-REGION.amazonaws.com/BUCKET_NAME/map/index.html where `REGION` is the region the bucket is located in and `BUCKET_NAME` is the bucket's name.

## Updating

You can update Minecraft Overviewer in the future by unzipping the latest zip into the `overviewer` folder.