module AwsRegions
  def build_usage_patterns(suffix)
    regions.map do |region|
      region[:prefixes].map do |prefix|
        [
          prefix,
          suffix
        ].reject(&:empty?).join('-')
      end
    end.flatten
  end
  def regions
    [
    { name: "US East (Ohio)", code: "us-east-2", prefixes: [ "USE2"] },
    { name: "US East (N. Virginia)", code: "us-east-1", prefixes: [ "USE1", "US", ""] },
    { name: "US West (N. California)", code: "us-west-1", prefixes: [ "USW1"] },
    { name: "US West (Oregon)", code: "us-west-2", prefixes: [ "USW2"] },
    { name: "Africa (Cape Town)", code: "af-south-1", prefixes: [ "AFS1"] },
    { name: "Asia Pacific (Hong Kong)", code: "ap-east-1", prefixes: [ "APE1"] },
    { name: "Asia Pacific (Hyderabad)", code: "ap-south-2", prefixes: [ "APS2"] },
    { name: "Asia Pacific (Jakarta)", code: "ap-southeast-3", prefixes: [ "APS3"] },
    { name: "Asia Pacific (Mumbai)", code: "ap-south-1", prefixes: [ "APS1"] },
    { name: "Asia Pacific (Osaka)", code: "ap-northeast-3", prefixes: [ "APN3"] },
    { name: "Asia Pacific (Seoul)", code: "ap-northeast-2", prefixes: [ "APN2"] },
    { name: "Asia Pacific (Singapore)", code: "ap-southeast-1", prefixes: [ "APS1"] },
    { name: "Asia Pacific (Sydney)", code: "ap-southeast-2", prefixes: [ "APS2"] },
    { name: "Asia Pacific (Tokyo)", code: "ap-northeast-1", prefixes: [ "APN1"] },
    { name: "Canada (Central)", code: "ca-central-1", prefixes: [ "CAC1"] },
    { name: "Europe (Frankfurt)", code: "eu-central-1", prefixes: [ "EUC1"] },
    { name: "Europe (Ireland)", code: "eu-west-1", prefixes: [ "EUW1", "EU"] },
    { name: "Europe (London)", code: "eu-west-2", prefixes: [ "EUW2"] },
    { name: "Europe (Milan)", code: "eu-south-1", prefixes: [ "EUS1"] },
    { name: "Europe (Paris)", code: "eu-west-3", prefixes: [ "EUW3"] },
    { name: "Europe (Spain)", code: "eu-south-2", prefixes: [ "EUS2"] },
    { name: "Europe (Stockholm)", code: "eu-north-1", prefixes: [ "EUN1"] },
    { name: "Europe (Zurich)", code: "eu-central-2", prefixes: [ "EUC2"] },
    { name: "Middle East (Bahrain)", code: "me-south-1", prefixes: [ "MES1"] },
    { name: "Middle East (UAE)", code: "me-central-1", prefixes: [ "MEC1"] },
    { name: "South America (São Paulo)", code: "sa-east-1", prefixes: [ "SAE1"] },
    { name: "AWS GovCloud (US-East)", code: "us-gov-east-1", prefixes: [ "USGEAST"] },
    { name: "AWS GovCloud (US-West)", code: "us-gov-west-1", prefixes: [ "USGWEST"] }]
  end
end
