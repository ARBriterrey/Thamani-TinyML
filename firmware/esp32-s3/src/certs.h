#ifndef CERTS_H
#define CERTS_H

// ---------------------------------------------------------------------------
// Server CA Certificate — ISRG Root X1
// Verified chain: edge.thamanihc.com -> Let's Encrypt E7 -> ISRG Root X1
// Expires: 2035-06-04.  Fetched: 2026-04-23.
// Source:  https://letsencrypt.org/certs/isrgrootx1.pem
// ---------------------------------------------------------------------------
const char* server_ca_cert =
  "-----BEGIN CERTIFICATE-----\n"
  "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\n"
  "-----END CERTIFICATE-----\n"
;

// ---------------------------------------------------------------------------
// Device Client Certificate — ESP32-Device-001
// Issued by: Thamani Root CA (self-signed, for mTLS)
// Used for mutual TLS authentication with the Nginx server.
// ---------------------------------------------------------------------------
const char* client_cert = 
  "-----BEGIN CERTIFICATE-----\n"
  "MIIESTCCAjECCQC8ML73gbq+SzANBgkqhkiG9w0BAQsFADBmMQswCQYDVQQGEwJV\n"
  "UzEOMAwGA1UECAwFU3RhdGUxDTALBgNVBAcMBENpdHkxEDAOBgNVBAoMB1RoYW1h\n"
  "bmkxDDAKBgNVBAsMA0lvVDEYMBYGA1UEAwwPVGhhbWFuaSBSb290IENBMB4XDTI2\n"
  "MDQxOTExMTkwNVoXDTMxMDQxODExMTkwNVowZzELMAkGA1UEBhMCVVMxDjAMBgNV\n"
  "BAgMBVN0YXRlMQ0wCwYDVQQHDARDaXR5MRAwDgYDVQQKDAdUaGFtYW5pMQwwCgYD\n"
  "VQQLDANJb1QxGTAXBgNVBAMMEEVTUDMyLURldmljZS0wMDEwggEiMA0GCSqGSIb3\n"
  "DQEBAQUAA4IBDwAwggEKAoIBAQCwn1ybGeLeMFa+sV2TkhuE3Kwjt1/mbHfvKOJN\n"
  "q7tFmqFgiF+kojrai8qmR8BWZfI13OKKX6cj4dAVAZTqTeluCRiWliGlC5OY5+L0\n"
  "FTAAVlSNaz+TnbHNaxcXoU9XUUSTchiEHPI/Z5c+I93Mqp8M817RHup9upYobtEo\n"
  "nAW3B8O37SXdXDSlm8B/I+VRyNuS+wANHUp+T43rk/qtt0+gWNffIZadj8xaWS+o\n"
  "VWFWMgSHSl3Z/dsBT7CX/8pNvtqLpdC4bJubyBiT7ArqV7gvmJVX7ifVleIub5Ub\n"
  "EEayOusWRcjg7KD9diVb1+HBN3d6AXIQzhXarpkPYllUxW9LAgMBAAEwDQYJKoZI\n"
  "hvcNAQELBQADggIBAG1aT9skEBYnkzJXLW2WgHTMuK7c3GKyXKPVkbgOFcgpHoNO\n"
  "ya10VpB7EnW+NYbs5+WhDYKcPzu3nBjKag4tMARNqpPkrT8Wf174IpXKIswU9V7v\n"
  "8SVSNv2i7DHiHG6QkZbhnstXEj17//OKQwgRlry+Z3m+vX6L7DVdCZQKYf4ETh7z\n"
  "9R6Rkj/ZSpgBNT2w90WB+fUKJDmG0LVyeQ1wxRpnn81evm5Bq0O6OiulDLogw+LK\n"
  "q/tdnmhTh/Y3/MzWrKT0v/EOITmQiHoLYgvBpLYIi5jb1NMyRGHQTgK8l20QoRrb\n"
  "nZtdsGyNdX4vr8/fA1yjeQ2KQjzD4j7hZYccg6yML4KDWcdSe3uvImeLEPjKxJ1x\n"
  "aGm/mK0/RM4cejeloSGQJHpPeCnyKCeCt6umWFf+beuGSjUQnoVMK7cJNFenNkr3\n"
  "x15s7KLsGRZ/ogYZzwaazNj4m81VS/jUBGYb2hsotLegLrPCj1HupXs6YwT3fk8G\n"
  "ty8eLTCybgVDD4d19CBgQ1oeuEN/QlDAksPsBWos4/96l696aEZERLHp5TRfluDs\n"
  "4ICQkdw5zozxYcurkGls+S/OuBWmPG3R01a09CEx5e0ZOBVbFYG5jULB6rjMD24X\n"
  "0Yl4fp3YB01RrSf92GUpeEOSpuHLLxwVXpfaNZ6OzCGVCPDCpWvSG7qlgnCr\n"
  "-----END CERTIFICATE-----\n"
;

const char* client_priv_key = 
  "-----BEGIN RSA PRIVATE KEY-----\n"
  "MIIEpAIBAAKCAQEAsJ9cmxni3jBWvrFdk5IbhNysI7df5mx37yjiTau7RZqhYIhf\n"
  "pKI62ovKpkfAVmXyNdziil+nI+HQFQGU6k3pbgkYlpYhpQuTmOfi9BUwAFZUjWs/\n"
  "k52xzWsXF6FPV1FEk3IYhBzyP2eXPiPdzKqfDPNe0R7qfbqWKG7RKJwFtwfDt+0l\n"
  "3Vw0pZvAfyPlUcjbkvsADR1Kfk+N65P6rbdPoFjX3yGWnY/MWlkvqFVhVjIEh0pd\n"
  "2f3bAU+wl//KTb7ai6XQuGybm8gYk+wK6le4L5iVV+4n1ZXiLm+VGxBGsjrrFkXI\n"
  "4Oyg/XYlW9fhwTd3egFyEM4V2q6ZD2JZVMVvSwIDAQABAoIBADblsZD74MoS2EN5\n"
  "OY6usSMAu/h1/LbQLA8H9B8UK6ccwuAQQzoWuphHLvuz/ZJdKYWYXEmKJZc/jr+Y\n"
  "uEKDaPSsmxnjHB4ClSPHn4EiPMM+EhXKqf4l26fvi0Pq/ZA0UE5L/lbB8IHInvfP\n"
  "ihcdSUZrNqNlKpldr2Jt31Dx/cy/dt1OD8uD28tkfrdGKwNWGiIwvn1ae68ec9Hq\n"
  "PxxyJPDVeJyUDh8pZfqLNWZJKDDHmeoFVslqWLuLbZiMbE174U8QgMjunQylWqpj\n"
  "K23WB+8Wq2Cp+zfmW3+TmZkQmFaJV519E+YPxUXOWexZHo5PvDxBrTDN4hNY2mIx\n"
  "4UIhEgECgYEA2QovTzFQf3BCKzBPI/SjQc80ga9nsrtegm1uLOhNFB9k51uh8vZd\n"
  "+J+g6h1CNpjNP1jRrg093wF48YFX8hNBrxpqGZM9LcmAUcQ5TIoFKvOZ02VQjvmI\n"
  "vvb2PJiAqIeTsNf+6RpJtfYOk+Rrr+2LZYrtwuPRfedHFWWyhUrEFoECgYEA0FPY\n"
  "3rh3ftNevAs7YMBKWsxCjStaCcD0Roe/l4vXDLCnaQ99/yeDzZjfiIJfBLYbaua+\n"
  "2n6kKHbtLXtSMvEeGWIuBMtcPrPcqO3WT97CIP0s2W6jyCPXm4ntmwJE/+CVmyDV\n"
  "xjl1Dhj6iTai+kKwlmU81lR8RLAugvIl0aBCF8sCgYB+vvPhy2q3AVei4RNWbAbq\n"
  "55ZCJazpM4J9qGouz3ozxiGm+lwZBsbZ6l6OWYfRWmqCE9xfSFxZXwLCBkbVl2lE\n"
  "WKidRt7zXjkRhwXvLKrX6mpqiUACPrcczhv+RxDbWlFldL3oYvGo0Yix1TMOCird\n"
  "ocQ3i9NLM0TPuhQGwyLAAQKBgQCIqKgYGiwRHzkC499UrW9ZNqrlji2nPlM/vSb6\n"
  "k7pDUdLQAWCms1Yr1X+1Pch0/7zmmG1USUUIYlNdxYr7bd5Pym7jqD9fxn8WtcYj\n"
  "aL4yA8Ka85Au5ww1tPoP+CIpNDsPoy94tBJMaChZQGUTBBJw5gJNmuhV6rjoH06d\n"
  "v6H7lwKBgQCwVwtSBgKm/qidD+Qm7DH9OKVVZuCl0RSttAaieGxSo5iKgNpRNW3N\n"
  "eFsTtQMEa7ssu+pQ/4TUf5pSVN3bB4QvzK7/FPcyvSYzfXUsP4UlcPcgFWKrKwCH\n"
  "NDUogibYE/HYvqIfBVZidvqfVu2Jd5+u6grUm5g0IDnCr7I8qzVnTQ==\n"
  "-----END RSA PRIVATE KEY-----\n"
;

#endif
