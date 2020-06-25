az keyvault list-deleted -o table

az keyvault purge --name nztfkv01

az webapp log tail -g nzlineast2-funcdemo-rg -n nzlineast2-demofunc-app
az webapp log tail -g nzlineast2-funcdemo-rg -n nzlineast2dotnetapp 



