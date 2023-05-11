#!/bin/bash
#get Disk-Usage as json
df -Ph |   jq -R -s '
    [
      split("\n") |
      .[] |
      if test("^/") then
        gsub(" +"; " ") | split(" ") | {mount: .[0], spacetotal: .[1], used: .[2], spaceavail: .[3], usedPercentage: .[4]}
      else
        empty
      end
    ]'