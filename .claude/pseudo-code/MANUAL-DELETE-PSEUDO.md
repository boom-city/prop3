## Delete tagged repos in boom-city organization

### Delete single remote
```
FUNCTION delete_remote(remote_name):
    CALL gh repo delete boom-city/remote_name --yes
    RETURN success
END FUNCTION
```

### List all remotes with tag "actions"
```
FUNCTION list_tagged_remotes():
    SET tagged_repos = empty list
    
    GET all_repos = gh api orgs/boom-city/repos --paginate --jq '.[].name'
    
    FOR EACH repo IN all_repos:
        GET repo_labels = gh api repos/boom-city/repo/labels --jq '.[].name'
        
        IF "actions" IN repo_labels:
            ADD "boom-city/" + repo TO tagged_repos
        END IF
    END FOR
    
    RETURN tagged_repos
END FUNCTION
```

### Delete all repos with "actions" tag
```
FUNCTION delete_all_tagged_repos():
    SET repos_to_delete = CALL list_tagged_remotes()
    
    FOR EACH repo IN repos_to_delete:
        PRINT "Deleting: " + repo
        CALL delete_remote(repo)
    END FOR
    
    RETURN success
END FUNCTION
```

