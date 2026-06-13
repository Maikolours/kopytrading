# 1. Rename files in the repository
$repo_dir = "c:\proyectos\APP KOPYTRADING\public\uploads\bots"

$old_gold = Join-Path $repo_dir "Elite_Gold_MAIKO_Sniper.mq5"
$new_gold = Join-Path $repo_dir "Maiko_Sniper_PRO_GOLD.mq5"
if (Test-Path $old_gold) {
    Rename-Item -Path $old_gold -NewName "Maiko_Sniper_PRO_GOLD.mq5" -Force
    Write-Output "Renamed $old_gold to Maiko_Sniper_PRO_GOLD.mq5"
}

$old_gold_client = Join-Path $repo_dir "Elite_Gold_MAIKO_Sniper_CLIENT.mq5"
$new_gold_client = Join-Path $repo_dir "Maiko_Sniper_PRO_GOLD_CLIENT.mq5"
if (Test-Path $old_gold_client) {
    Rename-Item -Path $old_gold_client -NewName "Maiko_Sniper_PRO_GOLD_CLIENT.mq5" -Force
    Write-Output "Renamed $old_gold_client to Maiko_Sniper_PRO_GOLD_CLIENT.mq5"
}

# Delete any old .ex5 files of Elite_Gold_MAIKO_Sniper in repo
Remove-Item -Path (Join-Path $repo_dir "Elite_Gold_MAIKO_Sniper*.ex5") -ErrorAction SilentlyContinue

# 2. Define terminal paths
$terminals = @(
    "C:\Users\Usuario\AppData\Roaming\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075",
    "C:\Users\Usuario\AppData\Roaming\MetaQuotes\Terminal\F762D69EEEA9B4430D7F17C82167C844"
)

# 3. Clean up and recreate BOTS MAIKO DEV folder structure in each terminal
foreach ($t in $terminals) {
    if (Test-Path $t) {
        $dev_folder = Join-Path $t "MQL5\Experts\BOTS MAIKO DEV"
        
        # Delete old dev folder completely to clear all mess
        if (Test-Path $dev_folder) {
            Remove-Item -Path $dev_folder -Recurse -Force -ErrorAction SilentlyContinue
            Write-Output "Deleted old dev folder: $dev_folder"
        }
        
        # Recreate dev folder and its single subfolder
        $maiko_subfolder = Join-Path $dev_folder "BOTS MAIKO"
        New-Item -ItemType Directory -Path $maiko_subfolder -Force | Out-Null
        Write-Output "Created clean subfolder: $maiko_subfolder"
        
        # Copy all 9 Maiko_*.mq5 files from repo into BOTS MAIKO
        $files_to_copy = @(
            "Maiko_BTC_Weekend.mq5",
            "Maiko_BTC_Weekend_CLIENT.mq5",
            "Maiko_BTC_Weekend_DEV.mq5",
            "Maiko_Sniper_PRO_GOLD.mq5",
            "Maiko_Sniper_PRO_GOLD_CLIENT.mq5",
            "Maiko_Sniper_PRO_GOLD_DEV.mq5",
            "Maiko_Sniper_PRO_CENT.mq5",
            "Maiko_Sniper_PRO_CENT_CLIENT.mq5",
            "Maiko_Sniper_PRO_CENT_DEV.mq5"
        )
        
        foreach ($f in $files_to_copy) {
            $src_path = Join-Path $repo_dir $f
            if (Test-Path $src_path) {
                Copy-Item -Path $src_path -Destination $maiko_subfolder -Force
                Write-Output "Copied $f to $maiko_subfolder"
            } else {
                Write-Warning "Source file not found: $src_path"
            }
        }
    }
}
