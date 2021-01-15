from django.shortcuts import render, get_object_or_404, redirect
from django.http import HttpResponse
from django.utils import timezone
from .models import Post, Comment
from .forms import PostModelForm, PostForm, CommentForm
from django.contrib.auth.models import User
from django.contrib.auth.decorators import login_required
from django.core.paginator import Paginator, EmptyPage, PageNotAnInteger


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
    # posts = Post.objects.filter(published_date__lte=timezone.now()).order_by('published_date')
    post_list = Post.objects.filter(published_date__lte=timezone.now()).order_by('published_date')
    paginator = Paginator(post_list, 2)
    page_no = request.GET.get('page')

    try:
        posts = paginator.page(page_no)
    except PageNotAnInteger:
        posts = paginator.page(1)
    except EmptyPage:
        posts = paginator.page(paginator.num_pages)

    return render(request, 'blog/post_list.html', {'posts': posts})


# Post 상세정보
def post_detail(request, pk):
    post = get_object_or_404(Post, pk=pk)
    return render(request, 'blog/post_detail.html', {'post': post})


# Post 등록 : ModelForm 사용
@login_required
def post_new(request):
    if request.method == 'POST':
        # 실제 등록 처리하기
        form = PostModelForm(request.POST)
        if form.is_valid():
            post = form.save(commit=False)
            # 작성자
            post.author = User.objects.get(username=request.user.username)
            # 글 게시일
            post.published_date = timezone.now()
            # 실제 등록됨
            post.save()
            return redirect('post_detail', pk=post.pk)
    else:
        # 등록하는 빈 form 을 보여주는 것
        form = PostModelForm()
    return render(request, 'blog/post_edit.html', {'form': form})


# Post 등록 : Form 사용
def post_new_form(request):
    if request.method == 'POST':
        form = PostForm(request.POST)
        if form.is_valid():
            # form 데이터가 clean 한 상태
            print(form.cleaned_data)
            post = Post.objects.create(author=User.objects.get(username=request.user.username),
                                       title=form.cleaned_data['title'],
                                       text=form.cleaned_data['text'],
                                       published_date=timezone.now())
            return redirect('post_detail', pk=post.pk)
    else:
        # 등록하는 빈 form 을 보여주는 것
        form = PostForm()
    return render(request, 'blog/post_edit.html', {'form': form})


# Post 수정: ModelForm 사용
@login_required
def post_edit(request, pk):
    post = get_object_or_404(Post, pk=pk)
    if request.method == 'POST':
        # 수정후 save 할때 반연하는 부분같음
        form = PostModelForm(request.POST, instance=post)
        if form.is_valid():
            post = form.save(commit=False)
            # 작성자
            post.author = User.objects.get(username=request.user.username)
            # 글 게시일
            post.published_date = timezone.now()
            # 실제 갱신됨
            post.save()
            return redirect('post_detail', pk=post.pk)
    else:
        # 맨처음 post 띄우기
        form = PostModelForm(instance=post)
    return render(request, 'blog/post_edit.html', {'form': form})


# Post 삭제
@login_required
def post_remove(request, pk):
    post = get_object_or_404(Post, pk=pk)
    post.delete()
    return redirect('post_list')


# Comment 등록
def add_comment_to_post(request, pk):
    post = get_object_or_404(Post, pk=pk)
    if request.method == 'POST':
        form = CommentForm(request.POST)
        if form.is_valid():
            comment = form.save(commit = False)
            comment.post = post
            comment.save()
            return redirect('post_detail', pk=post.pk)
    else:
        form = CommentForm()
    return render(request, 'blog/add_comment_to_post.html', {'form': form})


# Comment 승인
@login_required
def comment_approve(request, pk):
    comment = get_object_or_404(Comment, pk=pk)
    post_pk = comment.post.pk
    comment.approve()
    return redirect('post_detail', pk=post_pk)


# Comment 삭제
@login_required
def comment_remove(request, pk):
    comment = get_object_or_404(Comment, pk=pk)
    post_pk = comment.post.pk
    comment.delete()
    return redirect('post_detail', pk=post_pk)
