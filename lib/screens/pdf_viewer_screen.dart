import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
// ignore: avoid_web_libraries_in_flutter
import 'dart:ui_web' as ui;

import '../services/firebase_storage_service.dart';

class PdfViewerScreen extends StatefulWidget {
  final String fileUrl;
  final String title;

  const PdfViewerScreen({
    super.key,
    required this.fileUrl,
    required this.title,
  });

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  static const Color _deepBlue = Color(0xFF0D47A1);
  static const Color _skyBlue  = Color(0xFF1E88E5);

  bool    _loading    = true;
  bool    _registered = false;
  String? _error;
  String  _viewId     = '';
  String? _pdfBlobUrl;
  late    String _cleanUrl;

  @override
  void initState() {
    super.initState();
    _cleanUrl = FirebaseStorageService.prepareViewUrl(widget.fileUrl);
    if (kIsWeb) _load();
  }

  @override
  void dispose() {
    if (_pdfBlobUrl != null) html.Url.revokeObjectUrl(_pdfBlobUrl!);
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; _registered = false; });
    try {
      final response = await http.get(
        Uri.parse(_cleanUrl),
        headers: {'Accept': 'application/pdf,*/*'},
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 401 || response.statusCode == 403) {
        throw Exception(
          'This file is private on Cloudinary (HTTP ${response.statusCode}).\n\n'
          'Fix: Go to Cloudinary Dashboard → Settings → Upload Presets → '
          'Edit "${ _uploadPresetHint()}" → set Access Mode to "public".\n\n'
          'Then re-upload the file.',
        );
      }
      if (response.statusCode != 200) {
        throw Exception('Server returned ${response.statusCode}.');
      }

      final bytes   = response.bodyBytes;
      final blob    = html.Blob([bytes], 'application/pdf');
      final blobUrl = html.Url.createObjectUrlFromBlob(blob);
      _pdfBlobUrl   = blobUrl;

      _buildViewer(blobUrl);
      setState(() { _loading = false; });
    } catch (e) {
      setState(() { _loading = false; _error = e.toString(); });
    }
  }

  String _uploadPresetHint() {
    // Extract preset from URL if possible, else generic hint
    return 'snjp7oew';
  }

  void _buildViewer(String blobUrl) {
    final safeBlobUrl = blobUrl.replaceAll("'", "\\'");
    final viewId      = 'pdfjs-viewer-${blobUrl.hashCode.abs()}';

    final html_ = '''<!DOCTYPE html>
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
  new IntersectionObserver(es=>{
    es.forEach(e=>{
      if(e.isIntersecting){
        const i=cvs.indexOf(e.target);
        if(i>=0){cur=i+1;bar();}
      }
    });
  },{root:wrap,threshold:.4}).observe(cvs[0]||document.body);
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

    final blob   = html.Blob([html_], 'text/html');
    final bUrl   = html.Url.createObjectUrlFromBlob(blob);

    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory(viewId, (_) =>
      html.IFrameElement()
        ..src          = bUrl
        ..style.border = 'none'
        ..style.width  = '100%'
        ..style.height = '100%');

    setState(() { _viewId = viewId; _registered = true; });
  }

  void _openTab()  => html.window.open(_cleanUrl, '_blank');
  void _download() {
    final a = html.AnchorElement(href: _cleanUrl)
      ..setAttribute('download', '${widget.title}.pdf')
      ..setAttribute('target', '_blank');
    html.document.body?.append(a);
    a.click();
    a.remove();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF525659),
    appBar: AppBar(
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [_deepBlue, _skyBlue],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      elevation: 0,
      title: Text(widget.title,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          overflow: TextOverflow.ellipsis),
      actions: [
        IconButton(icon: const Icon(Icons.open_in_new_rounded),
            tooltip: 'Open in new tab', onPressed: _openTab),
        IconButton(icon: const Icon(Icons.download_rounded),
            tooltip: 'Download', onPressed: _download),
      ],
    ),
    body: _buildBody(),
  );

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(width: 44, height: 44,
            child: CircularProgressIndicator(color: Color(0xFF1E88E5), strokeWidth: 3)),
          SizedBox(height: 18),
          Text('Downloading PDF…', style: TextStyle(color: Colors.white70, fontSize: 14)),
        ],
      ));
    }

    if (_error != null) {
      return Center(child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.lock_outline_rounded, color: Colors.redAccent, size: 52),
          const SizedBox(height: 16),
          const Text('Could not load PDF',
              style: TextStyle(color: Colors.white, fontSize: 17,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(_error!,
                style: const TextStyle(color: Colors.white60, fontSize: 12, height: 1.6),
                textAlign: TextAlign.center),
          ),
          const SizedBox(height: 20),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            ElevatedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E88E5),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: _openTab,
              icon: const Icon(Icons.open_in_new_rounded, size: 16,
                  color: Color(0xFF1E88E5)),
              label: const Text('Open in tab',
                  style: TextStyle(color: Color(0xFF1E88E5))),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF1E88E5)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ]),
        ]),
      ));
    }

    if (kIsWeb && _registered) return HtmlElementView(viewType: _viewId);

    return const Center(
        child: CircularProgressIndicator(color: Color(0xFF1E88E5)));
  }
}