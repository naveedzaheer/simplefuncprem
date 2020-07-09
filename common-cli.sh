az keyvault list-deleted -o table

az keyvault purge --name nzwestus201-kv1
az keyvault purge --name nzwineast-demo-kv1
az keyvault purge --name nz2807win-demo-kv1


az webapp log tail -g nzlineast01-funcdemo-rg -n nzlineast01-demofunc-app
az webapp log tail -g nzlineast2-funcdemo-rg -n nzlineast2dotnetapp 



