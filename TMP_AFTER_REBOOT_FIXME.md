```
AttributeError: 'str' object has no attribute 'name'
```

This error occurs in `/home/riccardo/git/media-arneis/worktree/202604-e2e-no-mocks/util/generate_video.py`, line 43, when calling `client.operations.get(operation_resource_name)`. The `google.genai/operations.py` is then trying to access `operation.name` on what appears to be a string.

This implies that `client.operations.get(operation_resource_name)` is returning a string representing the operation name, rather than a full `Operation` object, which is unexpected behavior for the `google-genai` library's `get` method. It should always return an object that has a `.name` attribute.