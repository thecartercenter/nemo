# ELMO API
ELMO API is an api to allow other applications to access data.

# Developer Instructions

### Adding a new version
```rails generate versionist:new_api_version v1 API::V1 --header=name:Accept value:"application/vnd.getelmo.org+json; version=1"```

### Adding a new controller
```rails destroy versionist:new_controller missions API::V1```

### Making a new version
```rails generate versionist:copy_api_version <old version> <old module namespace> <new version> <new module namespace>```

#### More Information on versionist

https://github.com/bploetz/versionist
