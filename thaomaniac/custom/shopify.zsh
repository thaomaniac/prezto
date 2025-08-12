# Shopify CLI configuration and aliases

# Alias
alias sp='shopify'

# Load completion
if [[ -f "${0:h}/completions/_shopify" ]]; then
  source "${0:h}/completions/_shopify"
  compdef _shopify shopify
fi
