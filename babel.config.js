{
  "env": {
    "production": {
      "presets": [
        [
          "@babel/env",
          {
            "modules": false,
            "targets": {
              "browsers": "> 1%",
              "uglify": true
            },
            "useBuiltIns": "entry"
          }
        ],
        "@babel/react"
      ],
      "plugins": [
        "@babel/syntax-dynamic-import",
        "@babel/transform-runtime",
        "@babel/plugin-proposal-object-rest-spread",
        [
          "@babel/plugin-proposal-decorators",
          {
            "legacy": true
          }
        ],
        [
          "@babel/plugin-proposal-class-properties",
          {
            "loose": true
          }
        ]
      ]
    },
    "development": {
      "presets": [
        [
          "@babel/env",
          {
            "modules": false,
            "targets": {
              "browsers": "> 1%",
              "uglify": true
            },
            "useBuiltIns": "entry"
          }
        ],
        "@babel/react"
      ],
      "plugins": [
        "@babel/syntax-dynamic-import",
        "@babel/transform-runtime",
        "@babel/plugin-proposal-object-rest-spread",
        [
          "@babel/plugin-proposal-decorators",
          {
            "legacy": true
          }
        ],
        [
          "@babel/plugin-proposal-class-properties",
          {
            "loose": true
          }
        ]
      ]
    },
    "test": {
      "presets": [
        [
          "@babel/env",
          {
            "targets": {
              "browsers": "> 1%",
              "uglify": true
            },
            "useBuiltIns": "entry"
          }
        ],
        "@babel/react"
      ],
      "plugins": [
        "@babel/syntax-dynamic-import",
        "@babel/transform-runtime",
        "@babel/plugin-proposal-object-rest-spread",
        [
          "@babel/plugin-proposal-decorators",
          {
            "legacy": true
          }
        ],
        [
          "@babel/plugin-proposal-class-properties",
          {
            "loose": true
          }
        ]
      ]
    }
  }
}
