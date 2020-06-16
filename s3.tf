provider "aws" {
  region = "ap-south-1"
  profile = "terrauser"
}

//Creating S3 bucket
resource "aws_s3_bucket" "s3bucket" {
	bucket = "shailesh12341234"
	acl = "private"
    force_destroy = "true"  
    versioning {
		enabled = true
	}
}
//Downloading content from Github
resource "null_resource" "download"  {
	depends_on = [aws_s3_bucket.s3bucket,]
	provisioner "local-exec" {
		command = "git clone https://github.com/shaileshchoudhary/multihybridtask1images.git"
  	}
}
// Uploading file to bucket
resource "aws_s3_bucket_object" "upload_image1" {
	depends_on = [aws_s3_bucket.s3bucket , null_resource.download]   
        bucket = aws_s3_bucket.s3bucket.id
        key = "mainpage.png"    
	source = "multihybridtask1images/mainpage.png"
        
    acl = "public-read"
}

// Creating Cloudfront Distribution
resource "aws_cloudfront_distribution" "cdndistribution" {
	depends_on = [aws_s3_bucket.s3bucket , null_resource.download, ]
	origin {
		domain_name = aws_s3_bucket.s3bucket.bucket_regional_domain_name
		origin_id   = "S3-shailesh12341234-id"


		custom_origin_config {
			http_port = 80
			https_port = 80
			origin_protocol_policy = "match-viewer"
			origin_ssl_protocols = ["TLSv1", "TLSv1.1", "TLSv1.2"]
		}
	}
 
	enabled = true
  
	default_cache_behavior {
		allowed_methods = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
		cached_methods = ["GET", "HEAD"]
		target_origin_id = "S3-shailesh12341234-id"
 
		forwarded_values {
			query_string = false
 
			cookies {
				forward = "none"
			}
		}
		viewer_protocol_policy = "allow-all"
		min_ttl = 0
		default_ttl = 3600
		max_ttl = 86400
	}
 
	restrictions {
		geo_restriction {
 
			restriction_type = "none"
		}
	}
 
	viewer_certificate {
		cloudfront_default_certificate = true
	}
}



output "domain-name" {
	value = aws_cloudfront_distribution.cdndistribution.domain_name
}