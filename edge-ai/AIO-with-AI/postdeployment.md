# Post deployemnt

Once your resources have been deployed you will need to do the following to get the notebooks up running in Azure ML Studio and your Edge Pod functioning properly:

* When running the notebooks in AML your user (jim@contoso.com for instance) won't have permission to alter the storage account or add data to the storage. Please ensure that you have been assigned both Storage Blob Data Reader and Storage Blob Data Contributor roles.

* Run the Notebook(s)

    ``` 1-AutoML-ObjectDetection.ipynb ```