from django.shortcuts import render
from django.http import HttpResponse
from django.utils import timezone
from .models import Post


def post_list_response(request):
    name = 'Django'
    response = HttpResponse(f'<h2>Hello {name}!!</h2>', content_type="text/html")
    response.write(f'<h2>Hello {name}!!</h2>')
    response.write(f'<p>HTTP METHOD : {request.method}</p>')
    response.write(f'<p>HTTP ContentType : {request.content_type}</p>')
    return response

    # 또는 response 만들지 않고 return 문 하나로 끝내도 됨
    # return HttpResponse(f'''<h2>Hello {name}!!</h2><p>HTTP METHOD : {request.method}</p>''')


# Post 목록
def post_list(request):
    posts = Post.objects.filter(published_date__lte=timezone.now()).order_by('published_date')
    return render(request, 'blog/post_list.html', {'posts': posts})
