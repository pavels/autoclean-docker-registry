def clean_registry(registry_url, keep_tags)
  headers = {
    "Accept" => "application/vnd.docker.distribution.manifest.v2+json"
  }

  repositories = HTTParty.get("#{registry_url}/v2/_catalog", headers: headers)

  repositories = repositories['repositories'].map do |repository|

    tags = HTTParty.get("#{registry_url}/v2/#{repository}/tags/list", headers: headers)
    tags = tags["tags"]

    if tags
      tags_info = tags.map do |tag|
        manifest = HTTParty.get("#{registry_url}/v2/#{repository}/manifests/#{tag}", headers: headers)  
        digest = manifest.headers["docker-content-digest"]
        digest = JSON.parse(manifest)["config"]["digest"]
        
        resp = HTTParty.get("#{registry_url}/v2/#{repository}/blobs/#{digest}", headers: headers)  
        if resp.code == 200
          [ Time.parse(JSON.parse(resp.body)['created']), digest ]
        else
          nil
        end
      end
      [repository, tags_info.reject{ |ti| ti.nil? } ]
    else
      [repository, []]
    end
  end.to_h

  # puts repositories.map { |k,v| "#{k} -> " + v.map{ |ti| "#{ti[0]} - #{ti[1]}"}.join("\n")  }

  repositories.keys.each do |k|
    repositories[k].sort_by!{ |val| val[0] }.reverse!.shift(keep_tags)
  end

  repositories.each do |repo, digests|
    digests.each do |digest_info|
      HTTParty.delete("#{registry_url}/v2/#{repo}/manifests/#{digest_info[1]}")    
    end
  end

end
