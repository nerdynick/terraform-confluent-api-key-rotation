# API Key Rotation Terraform Module for Confluent Cloud

A simple module to handle the creation and rotation of Confluent Cloud API Keys. 
Rotation of keys are based on a number of days since creation and you can retain a configurable number of API keys per Owner.

# Important Note

Due to the limitation of Terraform and Time Based rotation.
You must execute th module on a regular bases that is equal to or less than the configured number of days to rotate.
If you do not, then you can run the risk of rotating out/deleting multiple keys on the next run.
This can get to the extent that all your current keys are removed on a single run. 
Which will prevent any current running process using them from continueing to be able to login and opperate against your Confluent Cloud Resources.