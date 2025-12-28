# CloudFront CDN Configuration

# CloudFront Origin Access Identity
resource "aws_cloudfront_origin_access_identity" "main" {
  comment = "OAI for ${local.name_prefix}"
}

# Update S3 bucket policy to allow CloudFront access
resource "aws_s3_bucket_policy" "cdn_assets" {
  count  = var.enable_cdn ? 1 : 0
  bucket = module.storage.assets_bucket_id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontAccess"
        Effect = "Allow"
        Principal = {
          AWS = aws_cloudfront_origin_access_identity.main.iam_arn
        }
        Action   = "s3:GetObject"
        Resource = "${module.storage.assets_bucket_arn}/*"
      }
    ]
  })
}

# CloudFront Distribution
resource "aws_cloudfront_distribution" "main" {
  count = var.enable_cdn ? 1 : 0
  
  enabled             = true
  is_ipv6_enabled    = true
  comment            = "${local.name_prefix} CDN"
  default_root_object = "index.html"
  price_class        = var.cdn_price_class
  
  # ALB Origin
  origin {
    domain_name = module.compute.alb_dns_name
    origin_id   = "alb-${local.name_prefix}"
    
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = var.certificate_arn != "" ? "https-only" : "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }
  
  # S3 Origin for Static Assets
  origin {
    domain_name = module.storage.assets_bucket_regional_domain_name
    origin_id   = "s3-${local.name_prefix}"
    
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.main.cloudfront_access_identity_path
    }
  }
  
  # Default Cache Behavior (Dynamic Content from ALB)
  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = "alb-${local.name_prefix}"
    
    forwarded_values {
      query_string = true
      headers      = ["Host", "Origin", "Access-Control-Request-Headers", "Access-Control-Request-Method"]
      
      cookies {
        forward = "all"
      }
    }
    
    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 0
    max_ttl                = 0
    compress               = true
  }
  
  # Cache Behavior for Static Assets
  ordered_cache_behavior {
    path_pattern     = "/static/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = "s3-${local.name_prefix}"
    
    forwarded_values {
      query_string = false
      headers      = ["Origin", "Access-Control-Request-Headers", "Access-Control-Request-Method"]
      
      cookies {
        forward = "none"
      }
    }
    
    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000
    compress               = true
  }
  
  # Cache Behavior for Images
  ordered_cache_behavior {
    path_pattern     = "*.jpg"
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "s3-${local.name_prefix}"
    
    forwarded_values {
      query_string = false
      
      cookies {
        forward = "none"
      }
    }
    
    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 604800
    max_ttl                = 31536000
    compress               = true
  }
  
  ordered_cache_behavior {
    path_pattern     = "*.png"
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "s3-${local.name_prefix}"
    
    forwarded_values {
      query_string = false
      
      cookies {
        forward = "none"
      }
    }
    
    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 604800
    max_ttl                = 31536000
    compress               = true
  }
  
  # Geo Restrictions
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
  
  # SSL Certificate
  viewer_certificate {
    cloudfront_default_certificate = var.cdn_certificate_arn == "" ? true : false
    acm_certificate_arn            = var.cdn_certificate_arn != "" ? var.cdn_certificate_arn : null
    ssl_support_method             = var.cdn_certificate_arn != "" ? "sni-only" : null
    minimum_protocol_version       = "TLSv1.2_2021"
  }
  
  # WAF Web ACL
  web_acl_id = var.enable_waf ? module.security.waf_web_acl_arn : null
  
  # Logging
  logging_config {
    bucket          = module.storage.logs_bucket_domain_name
    prefix          = "cloudfront/"
    include_cookies = false
  }
  
  # Custom Error Pages
  custom_error_response {
    error_code            = 404
    response_code         = 404
    response_page_path    = "/error-404.html"
    error_caching_min_ttl = 300
  }
  
  custom_error_response {
    error_code            = 500
    response_code         = 500
    response_page_path    = "/error-500.html"
    error_caching_min_ttl = 60
  }
  
  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-cdn"
    }
  )
}

# CloudFront Response Headers Policy
resource "aws_cloudfront_response_headers_policy" "security" {
  count = var.enable_cdn ? 1 : 0
  name  = "${local.name_prefix}-security-headers"
  
  security_headers_config {
    content_type_options {
      override = true
    }
    
    frame_options {
      frame_option = "DENY"
      override     = true
    }
    
    referrer_policy {
      referrer_policy = "strict-origin-when-cross-origin"
      override        = true
    }
    
    xss_protection {
      mode_block = true
      protection = true
      override   = true
    }
    
    strict_transport_security {
      access_control_max_age_sec = 31536000
      include_subdomains         = true
      preload                    = true
      override                   = true
    }
    
    content_security_policy {
      content_security_policy = "default-src 'self'; script-src 'self' 'unsafe-inline' https://cdn.jsdelivr.net; style-src 'self' 'unsafe-inline';"
      override                = true
    }
  }
  
  custom_headers_config {
    items {
      header   = "X-Environment"
      value    = var.environment
      override = false
    }
  }
}

# Route53 Record for CloudFront (if domain is provided)
resource "aws_route53_record" "cdn" {
  count   = var.enable_cdn && var.domain_name != "" ? 1 : 0
  zone_id = var.route53_zone_id
  name    = var.domain_name
  type    = "A"
  
  alias {
    name                   = aws_cloudfront_distribution.main[0].domain_name
    zone_id                = aws_cloudfront_distribution.main[0].hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "cdn_www" {
  count   = var.enable_cdn && var.domain_name != "" ? 1 : 0
  zone_id = var.route53_zone_id
  name    = "www.${var.domain_name}"
  type    = "A"
  
  alias {
    name                   = aws_cloudfront_distribution.main[0].domain_name
    zone_id                = aws_cloudfront_distribution.main[0].hosted_zone_id
    evaluate_target_health = false
  }
}
