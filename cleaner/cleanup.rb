REQUEST_HEADERS = {
  "Accept" => "application/vnd.docker.distribution.manifest.v2+json"
}

# Loads and parses json
def load_json(url)
  response = HTTParty.get(url, headers: REQUEST_HEADERS)
  if response.code == 200    
    return JSON.parse(response.body)
  else
    return nil
  end
end

def get_createion_time_v1(registry_url, repository, manifest)
  config_layer = manifest["history"].find { |m| !JSON.parse(m["v1Compatibility"])["created"].nil? }
  return nil if config_layer.nil?
  created_time = JSON.parse(config_layer["v1Compatibility"])["created"]
  Time.parse(created_time)
end

def get_createion_time_v2(registry_url, repository, manifest)
  digest = manifest.dig("config","digest")
  resp = load_json("#{registry_url}/v2/#{repository}/blobs/#{digest}")  
  resp.nil? ? nil : Time.parse(resp['created'])
end


def clean_registry(registry_url, keep_tags)
  repositories = load_json("#{registry_url}/v2/_catalog")

  repositories = repositories['repositories'].map do |repository|
    tags = load_json("#{registry_url}/v2/#{repository}/tags/list")

    if tags && tags.dig("tags")
      tags_info = tags.dig("tags").map do |tag|
        manifest = HTTParty.get("#{registry_url}/v2/#{repository}/manifests/#{tag}", headers: REQUEST_HEADERS) 
        manifest_digest = manifest.headers["docker-content-digest"]
        manifest = JSON.parse(manifest.body) 

        creation_time = nil
        if manifest["schemaVersion"] == 1
          creation_time = get_createion_time_v1(registry_url, repository, manifest)
        elsif manifest["schemaVersion"] == 2
          creation_time = get_createion_time_v2(registry_url, repository, manifest)
        end

        [creation_time, manifest_digest]
      end
      [repository, tags_info]
    else
      [repository, []]
    end
  end.to_h

  broken_manifests = {}

  # puts repositories.map { |k,v| "#{k} -> " + v.map{ |ti| "#{ti[0]} - #{ti[1]}"}.join("\n")  }

  repositories.keys.each do |k|
    broken_manifests[k] = repositories[k].select{ |val| val[0].nil? }.map{ |val| val[1] }
    repositories[k].reject!{ |val| val[0].nil? }
    repositories[k].sort_by!{ |val| val[0] }.reverse!.shift(keep_tags)
  end

  # puts repositories.map { |k,v| "#{k} -> " + v.map{ |ti| "#{ti[0]} - #{ti[1]}"}.join("\n")  }
  # puts broken_manifests.map { |k,v| "#{k} -> " + v.map{ |ti| "#{ti}"}.join("\n")  }

  repositories.each do |repo, digests|
    digests.each do |digest_info|
      HTTParty.delete("#{registry_url}/v2/#{repo}/manifests/#{digest_info[1]}")    
      puts "Deleted manifest #{digest_info[1]}"
    end
  end

  broken_manifests.each do |repo, digests|
    digests.each do |digest_info|
      HTTParty.delete("#{registry_url}/v2/#{repo}/manifests/#{digest_info}")
      puts "Deleted broken manifest #{digest_info}"
    end
  end

end
