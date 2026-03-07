// lib/screens/pdf_viewer_web.dart
//
// Web-only implementation — compiled ONLY when dart.library.html is available.
// All dart:html and dart:ui_web usage lives here, keeping the main
// pdf_viewer_screen.dart free of web-only libraries so it compiles on
// Android, iOS, and Desktop without errors.

// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
// ignore: avoid_web_libraries_in_flutter
import 'dart:ui_web' as ui;

import 'package:flutter/material.dart';

/// Downloads [url] as bytes, wraps them in a Blob URL, then builds a
/// self-contained PDF.js HTML page and registers it as a platform view.
///
/// Returns the [viewId] string that HtmlElementView should use, or throws.
Future<String> registerPdfViewer(String url) async {
  // ── Download the PDF ──────────────────────────────────────────────────
  final request = await html.HttpRequest.request(
    url,
    method: 'GET',
    responseType: 'arraybuffer',
    requestHeaders: {'Accept': 'application/pdf,*/*'},
  );

  if (request.status == 401 || request.status == 403) {
    throw Exception(
      'Access denied (HTTP ${request.status}).\n'
      'Make sure the file is publicly readable in your storage bucket.',
    );
  }
  if (request.status != 200) {
    throw Exception('Server returned HTTP ${request.status}.');
  }

  // ── Create a Blob URL for the raw PDF bytes ───────────────────────────
  final bytes     = request.response as dynamic; // ByteBuffer
  final pdfBlob   = html.Blob([bytes], 'application/pdf');
  final pdfBlobUrl = html.Url.createObjectUrlFromBlob(pdfBlob);

  // ── Build a self-contained PDF.js HTML viewer ─────────────────────────
  final safeUrl = pdfBlobUrl.replaceAll("'", "\\'");
  final html_   = _buildHtml(safeUrl);

  final htmlBlob  = html.Blob([html_], 'text/html');
  final htmlBlobUrl = html.Url.createObjectUrlFromBlob(htmlBlob);

  // ── Register the platform view ────────────────────────────────────────
  final viewId = 'pdfjs-viewer-${DateTime.now().millisecondsSinceEpoch}';

  // ignore: undefined_prefixed_name
  ui.platformViewRegistry.registerViewFactory(viewId, (_) =>
    html.IFrameElement()
      ..src          = htmlBlobUrl
      ..style.border = 'none'
      ..style.width  = '100%'
      ..style.height = '100%'
      ..allowFullscreen = true,
  );

  return viewId;
}

/// Opens [url] in a new browser tab.
void openInNewTab(String url) => html.window.open(url, '_blank');

/// Triggers a file download for [url] with the given [fileName].
void downloadFile(String url, String fileName) {
  final a = html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..setAttribute('target', '_blank');
  html.document.body?.append(a);
  a.click();
  a.remove();
}

// ── HTML template with embedded PDF.js viewer ─────────────────────────────

String _buildHtml(String safeBlobUrl) => '''<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<style>
  *{margin:0;padding:0;box-sizing:border-box}
  html,body{width:100%;height:100%;background:#525659;overflow:hidden}
  #bar{
    display:flex;align-items:center;justify-content:center;gap:8px;
    background:#323639;height:40px;padding:0 12px;
    color:#fff;font:13px sans-serif;user-select:none;flex-shrink:0
  }
  #bar button{
    background:#4a4d51;color:#fff;border:none;border-radius:4px;
    padding:3px 11px;cursor:pointer;font-size:13px
  }
  #bar button:hover{background:#1E88E5}
  #bar button:disabled{opacity:.35;cursor:default}
  #pages{
    width:100%;height:calc(100% - 40px);
    overflow-y:auto;overflow-x:auto;
    display:flex;flex-direction:column;align-items:center;
    padding:16px 0;gap:12px
  }
  canvas{display:block;box-shadow:0 2px 14px rgba(0,0,0,.55);background:#fff}
  #spin{
    position:fixed;top:50%;left:50%;transform:translate(-50%,-50%);
    color:#fff;font:14px sans-serif;text-align:center
  }
  .ring{
    width:40px;height:40px;margin:0 auto 10px;
    border:4px solid rgba(255,255,255,.15);border-top-color:#1E88E5;
    border-radius:50%;animation:sp .8s linear infinite
  }
  @keyframes sp{to{transform:rotate(360deg)}}
</style>
</head>
<body>
<div id="bar">
  <button id="pp" disabled>&#9664; Prev</button>
  <span id="pi" style="min-width:90px;text-align:center">Loading…</span>
  <button id="np" disabled>Next &#9654;</button>
  <button id="zo">&#8722;</button>
  <span id="zl" style="min-width:44px;text-align:center">150%</span>
  <button id="zi">&#43;</button>
</div>
<div id="pages"></div>
<div id="spin"><div class="ring"></div>Rendering…</div>
<script src="https://cdnjs.cloudflare.com/ajax/libs/pdf.js/3.11.174/pdf.min.js"></script>
<script>
const BLOB='$safeBlobUrl';
const lib=window['pdfjs-dist/build/pdf'];
lib.GlobalWorkerOptions.workerSrc=
  'https://cdnjs.cloudflare.com/ajax/libs/pdf.js/3.11.174/pdf.worker.min.js';

const wrap=document.getElementById('pages');
const spin=document.getElementById('spin');
const pi=document.getElementById('pi');
const pp=document.getElementById('pp');
const np=document.getElementById('np');
const zi=document.getElementById('zi');
const zo=document.getElementById('zo');
const zl=document.getElementById('zl');

let doc=null,total=0,cur=1,sc=1.5,cvs=[],busy=false;

function bar(){
  pi.textContent='Page '+cur+' / '+total;
  pp.disabled=cur<=1; np.disabled=cur>=total;
  zl.textContent=Math.round(sc*100)+'%';
}

async function renderAll(){
  if(busy)return; busy=true;
  wrap.innerHTML=''; cvs=[];
  for(let i=1;i<=total;i++){
    const pg=await doc.getPage(i);
    const vp=pg.getViewport({scale:sc});
    const cv=document.createElement('canvas');
    cv.width=vp.width; cv.height=vp.height;
    wrap.appendChild(cv); cvs.push(cv);
    await pg.render({canvasContext:cv.getContext('2d'),viewport:vp}).promise;
  }
  busy=false;
  cvs.forEach((c,i)=>{
    new IntersectionObserver(es=>{
      if(es[0].isIntersecting){cur=i+1;bar();}
    },{root:wrap,threshold:.4}).observe(c);
  });
}

async function init(){
  try{
    doc=await lib.getDocument(BLOB).promise;
    total=doc.numPages;
    spin.style.display='none';
    await renderAll();
    bar();
    np.disabled=total<=1;
  }catch(e){
    spin.style.display='none';
    wrap.innerHTML='<p style="color:#ff6b6b;font:14px sans-serif;margin-top:40px;text-align:center">'+e.message+'</p>';
  }
}

pp.onclick=()=>{if(cur>1){cur--;cvs[cur-1]?.scrollIntoView({behavior:'smooth',block:'start'});bar();}};
np.onclick=()=>{if(cur<total){cur++;cvs[cur-1]?.scrollIntoView({behavior:'smooth',block:'start'});bar();}};
zi.onclick=async()=>{if(sc>=3||busy)return;sc=Math.min(sc+.25,3);await renderAll();bar();};
zo.onclick=async()=>{if(sc<=.5||busy)return;sc=Math.max(sc-.25,.5);await renderAll();bar();};

init();
</script>
</body>
</html>''';