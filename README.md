# API Key Rotation Terraform Module for Confluent Cloud

A simple module to handle the creation and rotation of Confluent Cloud API Keys.
The rotation of keys is based on the number of days since creation and you can retain a configurable number of API keys per Owner.

# Important Note

Due to the limitation of Terraform and Time Based rotation.
You must execute the module regularly, on a frequency that is equal to or less than the configured number of days to rotate.
If you do not, then you can run the risk of rotating out/deleting multiple keys on the next run.
This can get to the extent that all your current keys are removed on a single run. 
This will prevent any current running process, that is currently using the older keys, from continuing to be able to log in and operate against your Confluent Cloud Resources.