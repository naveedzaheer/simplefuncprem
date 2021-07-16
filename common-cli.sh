az keyvault list-deleted -o table

az keyvault purge --name nzattsearchkv04
az keyvault purge --name nzsearchkv3
az keyvault purge --name nzattsearchkv
az keyvault purge --name nzlinwest2b-demo-kv1
az keyvault purge --name searchkv3
az keyvault purge --name nzsearchkv


az webapp log tail -g nzlinwest2b-funcdemo-rg -n nzlinwest2b-demofunc-app
az webapp log tail -g nzlineast2b-funcdemo-rg -n nzlineast2b-demofunc-app 

#!/usr/bin/env bash
for queue in $(az storage queue list --account-name nzattfuncstorage --account-key wJALXGVwd2ZLqD+zWl8Nv6V0BPEPdX3kV4WajmzyyHgQGvcJww7dIr6uF+/4AB4Y2l2lPrVrmfct5nMIYEyniw== --query [].name -o tsv); do
    az storage queue delete --account-name nzattfuncstorage --account-key wJALXGVwd2ZLqD+zWl8Nv6V0BPEPdX3kV4WajmzyyHgQGvcJww7dIr6uF+/4AB4Y2l2lPrVrmfct5nMIYEyniw== --name $queue
    #echo $queue.name
done



