# Template for GitLab NGINX VTS Metrics Validation

Template to test and validate GitLab's nginx VTS (Virtual Host
Traffic Status) module configuration. This template helps troubleshoot
VTS metrics exposure and histogram configuration in GitLab.

---

## Content
- Minimal GitLab setup with HTTP-only configuration
- All exporters enabled on standard ports
- VTS enabled on nginx status port 9999
- Post-deploy script that validates VTS endpoints and displays metrics

## Uses
- Verifying VTS module availability in GitLab. 
- Testing custom histogram bucket configuration
- Understanding how GitLab exposes VTS metrics (/metrics vs /status)
- Debugging Prometheus scrape configurations for nginx metrics
