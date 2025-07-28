import functions_framework

@functions_framework.http
def test_function(request):
    """A simple test function to verify Firebase Functions deployment."""
    return "Hello from Firebase Functions!" 