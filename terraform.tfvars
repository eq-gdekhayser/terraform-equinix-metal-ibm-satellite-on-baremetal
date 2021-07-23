//equinix metal
metal_create_project      = false
metal_project_id          = "4354df5a-d9c4-4e43-a8c5-82069625f40b"
metal_api_auth_token      = "Tsf2voRC21KKvjTtSuF99uAZVZQYUP4f"
metal_device_metro        = "da" // YOU MIGHT CHOOSE A DIFFERENT EQUINIX METAL METRO LOCATION
control_plane_plan        = "c3.small.x86" // YOU MIGHT CHOOSE A DIFFERENT SERVER SIZE
data_plane_plan           = "c3.small.x86" // YOU MIGHT CHOOSE A DIFFERENT SERVER SIZE
stack_name                = "eq-sat-poc-v2"
rhel_submanager_username  = "gdekhayser_p"
rhel_submanager_password  = "Voyant1500!"

//ibm
ibm_create_location       = true
ibm_create_resource_group = false
ibm_resource_group_name   = "cloud-pak-sandbox"
ibm_sat_location_name     = "satlab07212101"
ibm_sat_managed_from      = "wdc04"
ibm_cp_host_labels        = ["owner:me", "provider:equinix"]
ibm_dp_host_labels        = ["owner:me", "provider:equinix", "type:worker"] 
ibm_cloud_api_key         = "CCOi97M-qUtp6ysZHwaVsS3b-6jXU8NfkhRaTE8Xj74A"
ibm_region                = "us-east" // (string) SUPPORTED REGIONS FOR SATELLITE ARE "us-east" AND "eu-gb"
ibm_dp_host_count         = 3 // YOU MIGHT NEED MORE WORKER NODES
ibm_cp_host_count         = 3 // YOU MIGHT NEED MORE MANAGER NODES